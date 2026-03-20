import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../ai/ai_controller.dart';
import '../ai/wake_word_service.dart';
import '../core/system_controller.dart';
import 'voice_response_service.dart';

class VoiceListenerService {
VoiceListenerService({
SpeechToText? speechToText,
WakeWordService? wakeWordService,
SystemController? systemController,
AIController? aiController,
Logger? logger,
VoiceResponseService? voiceResponseService,
})  : _speech = speechToText ?? SpeechToText(),
_wakeWordService = wakeWordService ?? WakeWordService(),
_systemController = systemController ?? SystemController(),
_aiController = aiController ?? AIController(),
_voice = voiceResponseService ?? VoiceResponseService(),
_logger = logger ?? Logger();

final SpeechToText _speech;
final WakeWordService _wakeWordService;
final SystemController _systemController;
final AIController _aiController;
final VoiceResponseService _voice;
final Logger _logger;

static const MethodChannel _callEventsChannel =
MethodChannel('smart_assistant/call_events');

bool _isInitialized = false;
bool _isListening = false;
bool _isStartingListening = false;
bool _wakeWordActivated = false;
bool _isWaitingCallResponse = false;
bool _isAssistantSpeaking = false;
bool _isDisposing = false;
bool _suppressAutoRestart = false;

String _lastProcessedText = '';
DateTime? _lastWakeTime;
DateTime? _lastListenStartedAt;
Timer? _restartTimer;

static const Duration _wakeSessionTimeout = Duration(seconds: 10);
static const Duration _restartDelay = Duration(seconds: 3);
static const Duration _resumeAfterSpeakDelay = Duration(milliseconds: 1200);
static const Duration _minimumStableListenWindow = Duration(seconds: 2);

bool get isInitialized => _isInitialized;
bool get isListening => _isListening;
bool get isWakeWordActivated => _wakeWordActivated;
bool get isWaitingCallResponse => _isWaitingCallResponse;

// =========================
// INITIALIZE
// =========================

Future<void> initialize() async {
if (_isInitialized) {
_logger.d('VoiceListenerService already initialized');
return;
}

try {  
  await _wakeWordService.initialize();  
  await _systemController.initialize();  
  await _voice.initialize();  

  _callEventsChannel.setMethodCallHandler(_handleNativeCallEvent);  

  final available = await _speech.initialize(  
    onStatus: _onSpeechStatus,  
    onError: _onSpeechError,  
    debugLogging: true,  
  );  

  if (!available) {  
    _logger.e('Speech recognition is not available on this device');  
    return;  
  }  

  _isInitialized = true;  
  _logger.i('VoiceListenerService initialized successfully');  
} catch (e, stackTrace) {  
  _logger.e(  
    'Failed to initialize VoiceListenerService',  
    error: e,  
    stackTrace: stackTrace,  
  );  
}

}

// =========================
// START LISTENING
// =========================

Future<void> startListening() async {
if (_isDisposing) {
return;
}

if (_isStartingListening) {  
  return;  
}  

if (_isAssistantSpeaking) {  
  _logger.d('Start listening skipped because assistant is speaking');  
  return;  
}  

if (!_isInitialized) {  
  await initialize();  
}  

if (!_isInitialized) {  
  _logger.w('Start listening aborted because initialization failed');  
  return;  
}  

if (_isListening) {  
  _logger.d('Listening already active');  
  return;  
}  

_restartTimer?.cancel();  
_isStartingListening = true;  

try {  
  final localeId = await _resolvePreferredLocaleId();  

  await _speech.listen(  
    onResult: _onSpeechResult,  
    listenFor: const Duration(minutes: 5),  
    pauseFor: const Duration(seconds: 8),  
    partialResults: true,  
    cancelOnError: false,  
    listenMode: ListenMode.dictation,  
    localeId: localeId,  
  );  

  _isListening = true;  
  _lastListenStartedAt = DateTime.now();  
  _logger.i('Voice listening started, locale: $localeId');  
} catch (e, stackTrace) {  
  _isListening = false;  
  _logger.e(  
    'Failed to start listening',  
    error: e,  
    stackTrace: stackTrace,  
  );  
  _scheduleRestart();  
} finally {  
  _isStartingListening = false;  
}

}

Future<String?> _resolvePreferredLocaleId() async {
try {
final locales = await _speech.locales();

for (final locale in locales) {  
    final id = locale.localeId.toLowerCase();  
    if (id == 'ar_eg') {  
      return locale.localeId;  
    }  
  }  

  for (final locale in locales) {  
    final id = locale.localeId.toLowerCase();  
    if (id.startsWith('ar')) {  
      return locale.localeId;  
    }  
  }  

  final systemLocale = await _speech.systemLocale();  
  return systemLocale?.localeId;  
} catch (_) {  
  return null;  
}

}

// =========================
// STOP LISTENING
// =========================

Future<void> stopListening() async {
_restartTimer?.cancel();
_suppressAutoRestart = true;

if (!_isListening && !_isStartingListening) {  
  return;  
}  

try {  
  await _speech.cancel();  
} catch (e, stackTrace) {  
  _logger.e(  
    'Failed to stop listening',  
    error: e,  
    stackTrace: stackTrace,  
  );  
} finally {  
  _isListening = false;  
  _isStartingListening = false;  
  _logger.i('Voice listening stopped');  
}

}

// =========================
// DISPOSE
// =========================

Future<void> dispose() async {
_isDisposing = true;
_restartTimer?.cancel();
await stopListening();
_callEventsChannel.setMethodCallHandler(null);
}

// =========================
// SPEECH CALLBACKS
// =========================

void _onSpeechStatus(String status) {
_logger.d('Speech status: $status');

if (status == 'listening') {  
  _isListening = true;  
  return;  
}  

if (status == 'done' || status == 'notListening') {  
  _isListening = false;  

  if (_isDisposing) {  
    _logger.d('Speech stopped because service is disposing');  
    return;  
  }  

  if (_suppressAutoRestart) {  
    _logger.d('Speech stopped while auto restart is suppressed');  
    return;  
  }  

  if (_isAssistantSpeaking) {  
    _logger.d('Speech stopped because assistant is speaking');  
    return;  
  }  

  final startedAt = _lastListenStartedAt;  
  if (startedAt != null &&  
      DateTime.now().difference(startedAt) < _minimumStableListenWindow) {  
    _logger.d('Speech stopped too early, scheduling delayed restart');  
    _scheduleRestart(delay: const Duration(seconds: 4));  
    return;  
  }  

  _scheduleRestart();  
}

}

void _onSpeechError(dynamic error) {
_logger.e('Speech error: $error');
_isListening = false;

if (_isDisposing) {  
  return;  
}  

if (_suppressAutoRestart) {  
  _logger.d('Speech error ignored because auto restart is suppressed');  
  return;  
}  

if (_isAssistantSpeaking) {  
  return;  
}  

_scheduleRestart();

}

Future<void> _onSpeechResult(dynamic result) async {
try {
final text = _normalize(result.recognizedWords as String? ?? '');

if (text.isEmpty) {  
    return;  
  }  

  _logger.d('Recognized: $text');  

  if (_isDuplicatePartial(text)) {  
    return;  
  }  

  // =========================  
  // CALL RESPONSE MODE  
  // =========================  

  if (_isWaitingCallResponse) {  
    final commandResult = await _systemController.handleCommand(text);  

    if (commandResult.handled || _looksLikeCallDecision(text)) {  
      _isWaitingCallResponse = false;  
      _clearWakeSession();  
    }  

    return;  
  }  

  // =========================  
  // WAKE WORD DETECTION  
  // =========================  

  if (!_wakeWordActivated) {  
    if (_wakeWordService.detectWakeWord(text)) {  
      final commandOnly = _removeWakeWord(text);  
      _activateWakeSession();  

      if (commandOnly.isNotEmpty) {  
        await _handleAssistantCommand(commandOnly);  
      } else {  
        await _speakAndResume('سمعاك');  
      }  
    }  

    return;  
  }  

  // =========================  
  // WAKE SESSION TIMEOUT  
  // =========================  

  if (_isWakeSessionExpired()) {  
    _logger.d('Wake session expired');  
    _clearWakeSession();  
    return;  
  }  

  // =========================  
  // NORMAL COMMAND ROUTING  
  // =========================  

  await _handleAssistantCommand(text);  
} catch (e, stackTrace) {  
  _logger.e(  
    'Error while processing speech result',  
    error: e,  
    stackTrace: stackTrace,  
  );  
}

}

// =========================
// COMMAND HANDLING
// =========================

Future<void> _handleAssistantCommand(String text) async {
await _pauseListeningForAssistantSpeech();

try {  
  final aiResult = await _aiController.processVoice(text);  

  if (aiResult.handled) {  
    _logger.i(  
      'Command handled by AIController via route: ${aiResult.routeType.name}',  
    );  
  } else if (!aiResult.isIgnored) {  
    _logger.d('AIController could not fully handle the command');  
  }  
} finally {  
  _clearWakeSession();  
  await _resumeListeningAfterAssistantSpeech();  
}

}

// =========================
// CALL EVENTS
// =========================

Future<void> _handleNativeCallEvent(MethodCall call) async {
if (call.method != 'incomingCall') {
_logger.w('Unknown native call event: ${call.method}');
return;
}

final number = (call.arguments as String?)?.trim();  
final incomingNumber =  
    (number == null || number.isEmpty) ? 'رقم غير معروف' : number;  

_logger.i('Incoming call event received: $incomingNumber');  

_isWaitingCallResponse = true;  
_clearWakeSession();  

await _pauseListeningForAssistantSpeech();  

try {  
  await _voice.speak(  
    'مكالمة واردة من $incomingNumber. هل تريد الرد أم الرفض؟',  
  );  
  await _systemController.onIncomingCall(incomingNumber);  
} finally {  
  await _resumeListeningAfterAssistantSpeech();  
}

}

// =========================
// SPEAK / PAUSE HELPERS
// =========================

Future<void> _speakAndResume(String text) async {
await _pauseListeningForAssistantSpeech();

try {  
  await _voice.speak(text);  
} finally {  
  await _resumeListeningAfterAssistantSpeech();  
}

}

Future<void> _pauseListeningForAssistantSpeech() async {
_isAssistantSpeaking = true;
_suppressAutoRestart = true;
_restartTimer?.cancel();

try {  
  if (_isListening || _isStartingListening) {  
    await _speech.cancel();  
  }  
} catch (e, stackTrace) {  
  _logger.e(  
    'Failed to pause listening before assistant speech',  
    error: e,  
    stackTrace: stackTrace,  
  );  
} finally {  
  _isListening = false;  
  _isStartingListening = false;  
}

}

Future<void> _resumeListeningAfterAssistantSpeech() async {
await Future<void>.delayed(_resumeAfterSpeakDelay);

if (_isDisposing) {  
  return;  
}  

_isAssistantSpeaking = false;  
_suppressAutoRestart = false;  
await startListening();

}

// =========================
// HELPERS
// =========================

String _removeWakeWord(String text) {
var cleaned = text;

for (final word in const [  
  'يا siri',  
  'siri',  
  'يا nada',  
  'nada',  
  'يا مساعدي',  
  'مساعدي',  
  'يا مساعد',  
  'مساعد',  
  'assistant',  
  'hey assistant',  
  'ok assistant',  
  'يا',  
]) {  
  cleaned = cleaned.replaceAll(word.toLowerCase(), ' ');  
}  

return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

}

void _activateWakeSession() {
_wakeWordActivated = true;
_lastWakeTime = DateTime.now();
_lastProcessedText = '';
_logger.i('Wake word detected');
}

void _clearWakeSession() {
_wakeWordActivated = false;
_lastWakeTime = null;
_lastProcessedText = '';
}

bool _isWakeSessionExpired() {
if (_lastWakeTime == null) {
return true;
}

return DateTime.now().difference(_lastWakeTime!) > _wakeSessionTimeout;

}

bool _isDuplicatePartial(String text) {
if (text == _lastProcessedText) {
return true;
}

_lastProcessedText = text;  
return false;

}

bool _looksLikeCallDecision(String text) {
return _containsAny(
text,
const [
'رد',
'اقبل',
'ارفض',
'اقفل',
'answer',
'accept',
'reject',
],
);
}

bool _containsAny(String text, List<String> values) {
for (final value in values) {
if (text.contains(value)) {
return true;
}
}

return false;

}

void _scheduleRestart({Duration? delay}) {
if (_isDisposing || _isAssistantSpeaking || _isStartingListening) {
return;
}

if (_suppressAutoRestart) {  
  _logger.d('Restart skipped because auto restart is suppressed');  
  return;  
}  

_restartTimer?.cancel();  
_restartTimer = Timer(delay ?? _restartDelay, () async {  
  if (_isDisposing || _isAssistantSpeaking || _suppressAutoRestart) {  
    return;  
  }  

  if (_isListening) {  
    return;  
  }  

  await startListening();  
});

}

String _normalize(String text) {
return text
.toLowerCase()
.trim()
.replaceAll(RegExp(r'[،,.!?؟]'), ' ')
.replaceAll(RegExp(r'\s+'), ' ');
}
}

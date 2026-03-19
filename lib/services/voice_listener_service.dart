import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../ai/ai_controller.dart';
import '../ai/wake_word_service.dart';
import '../core/system_controller.dart';
import 'voice_response_service.dart'; // ✅ إضافة

class VoiceListenerService {
  VoiceListenerService({
    SpeechToText? speechToText,
    WakeWordService? wakeWordService,
    SystemController? systemController,
    AIController? aiController,
    Logger? logger,
    VoiceResponseService? voiceResponseService, // ✅ إضافة
  })  : _speech = speechToText ?? SpeechToText(),
        _wakeWordService = wakeWordService ?? WakeWordService(),
        _systemController = systemController ?? SystemController(),
        _aiController = aiController ?? AIController(),
        _voice = voiceResponseService ?? VoiceResponseService(), // ✅ إضافة
        _logger = logger ?? Logger();

  final SpeechToText _speech;
  final WakeWordService _wakeWordService;
  final SystemController _systemController;
  final AIController _aiController;
  final VoiceResponseService _voice; // ✅ إضافة
  final Logger _logger;

  static const MethodChannel _callEventsChannel =
      MethodChannel('smart_assistant/call_events');

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isRestarting = false;
  bool _wakeWordActivated = false;
  bool _isWaitingCallResponse = false;

  String _lastProcessedText = '';
  DateTime? _lastWakeTime;
  Timer? _restartDebounceTimer;

  static const Duration _wakeSessionTimeout = Duration(seconds: 10);
  static const Duration _restartDelay = Duration(milliseconds: 450);

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
      await _voice.initialize(); // ✅ مهم جدًا

      _callEventsChannel.setMethodCallHandler(_handleNativeCallEvent);

      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
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
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      _logger.w('Start listening aborted because initialization failed');
      return;
    }

    if (_isListening) {
      return;
    }

    try {
      _isListening = true;

      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );

      _logger.i('Voice listening started');
    } catch (e, stackTrace) {
      _isListening = false;
      _logger.e(
        'Failed to start listening',
        error: e,
        stackTrace: stackTrace,
      );
      _scheduleRestart();
    }
  }

  // =========================
  // STOP LISTENING
  // =========================

  Future<void> stopListening() async {
    _restartDebounceTimer?.cancel();

    if (!_isListening) {
      return;
    }

    try {
      await _speech.stop();
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to stop listening',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isListening = false;
      _logger.i('Voice listening stopped');
    }
  }

  // =========================
  // DISPOSE
  // =========================

  Future<void> dispose() async {
    _restartDebounceTimer?.cancel();
    await stopListening();
    _callEventsChannel.setMethodCallHandler(null);
  }

  // =========================
  // SPEECH CALLBACKS
  // =========================

  void _onSpeechStatus(String status) {
    _logger.d('Speech status: $status');

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _scheduleRestart();
    }
  }

  void _onSpeechError(dynamic error) {
    _logger.e('Speech error: $error');
    _isListening = false;
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
        await _systemController.handleCommand(text);

        if (_looksLikeCallDecision(text)) {
          _isWaitingCallResponse = false;
          _clearWakeSession();
        }

        return;
      }

      // =========================
      // WAKE WORD DETECTION (FIXED)
      // =========================
      if (!_wakeWordActivated) {
        if (_wakeWordService.detectWakeWord(text)) {
          final commandOnly = _removeWakeWord(text);

          _activateWakeSession();

          if (commandOnly.isNotEmpty) {
            final aiResult = await _aiController.processVoice(commandOnly);

            if (aiResult.handled) {
              _logger.i(
                'Command handled immediately after wake word via route: ${aiResult.routeType.name}',
              );
            } else if (!aiResult.isIgnored) {
              _logger.d('AIController could not fully handle the command');
            }

            _clearWakeSession();
          } else {
            await _voice.speak('سمعاك'); // ✅ رد صوتي
          }

          return;
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
      final aiResult = await _aiController.processVoice(text);

      if (aiResult.handled) {
        _logger.i(
          'Command handled by AIController via route: ${aiResult.routeType.name}',
        );
      } else if (!aiResult.isIgnored) {
        _logger.d('AIController could not fully handle the command');
      }

      _clearWakeSession();
    } catch (e, stackTrace) {
      _logger.e(
        'Error while processing speech result',
        error: e,
        stackTrace: stackTrace,
      );
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

    await _voice.speak('مكالمة واردة من $incomingNumber هل تريد الرد أم الرفض'); // ✅ صوت
    await _systemController.onIncomingCall(incomingNumber);
  }

  // =========================
  // HELPERS
  // =========================

  String _removeWakeWord(String text) {
    final wakeWord = _wakeWordService.getWakeWord().toLowerCase().trim();

    var cleaned = text;

    if (wakeWord.isNotEmpty) {
      cleaned = cleaned.replaceAll(wakeWord, ' ');
    }

    const defaults = ['يا nada', 'nada', 'assistant'];

    for (final word in defaults) {
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

  void _scheduleRestart() {
    if (_isRestarting) {
      return;
    }

    _restartDebounceTimer?.cancel();
    _restartDebounceTimer = Timer(_restartDelay, () async {
      if (_isListening) {
        return;
      }

      _isRestarting = true;
      try {
        await startListening();
      } finally {
        _isRestarting = false;
      }
    });
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[،,.!?؟]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

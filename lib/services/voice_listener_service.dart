import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:logger/logger.dart';

import '../ai/ai_controller.dart';
import '../ai/wake_word_service.dart';
import '../core/system_controller.dart'; // 🔥 جديد
import 'voice_response_service.dart';

class VoiceListenerService {
  final SpeechToText _speech = SpeechToText();
  final WakeWordService _wakeWordService = WakeWordService();
  final AIController _aiController = AIController();
  final VoiceResponseService _voice = VoiceResponseService();
  final SystemController _systemController = SystemController(); // 🔥 مهم

  final Logger _logger = Logger();

  static const MethodChannel _callChannel =
      MethodChannel('smart_assistant/call_events');

  static const MethodChannel _callControlChannel =
      MethodChannel('smart_assistant/call_control');

  bool _isListening = false;
  bool _wakeWordActivated = false;

  bool _isWaitingCallResponse = false;

  String _lastCommand = "";
  DateTime _lastWakeTime = DateTime.now();

  bool _isRestarting = false;

  // =====================================
  // INITIALIZE
  // =====================================

  Future<void> initialize() async {
    try {
      await _wakeWordService.initialize();
      await _systemController.initialize(); // 🔥 مهم

      _callChannel.setMethodCallHandler(_handleCallEvents);

      bool available = await _speech.initialize(
        onStatus: (status) {
          _logger.d("Speech status: $status");

          if (status == "done") {
            _isListening = false;
            _restartListening();
          }
        },
        onError: (error) {
          _logger.e("Speech error: $error");

          _isListening = false;
          _restartListening();
        },
      );

      if (available) {
        _logger.i("Speech initialized successfully");
        startListening();
      } else {
        _logger.e("Speech not available");
      }
    } catch (e) {
      _logger.e("Initialization error: $e");
    }
  }

  // =====================================
  // HANDLE CALL EVENTS 🔥
  // =====================================

  Future<void> _handleCallEvents(MethodCall call) async {
    if (call.method == "incomingCall") {
      String number = call.arguments ?? "رقم غير معروف";

      _logger.i("Incoming call: $number");

      _isWaitingCallResponse = true;

      await _systemController.onIncomingCall(number); // 🔥 ربط جديد
    }
  }

  // =====================================
  // START LISTENING
  // =====================================

  Future<void> startListening() async {
    if (_isListening) return;

    try {
      _isListening = true;

      await _speech.listen(
        onResult: (result) async {
          try {
            String text = _normalize(result.recognizedWords);

            if (text.isEmpty) return;

            _logger.d("Heard: $text");

            // =====================================
            // 🔥 CALL RESPONSE MODE
            // =====================================

            if (_isWaitingCallResponse) {
              await _handleCallResponse(text);
              _isWaitingCallResponse = false;

              await stopListening();
              return;
            }

            // ===============================
            // WAKE WORD
            // ===============================

            if (!_wakeWordActivated) {
              if (_wakeWordService.detectWakeWord(text)) {
                _wakeWordActivated = true;
                _lastWakeTime = DateTime.now();

                _logger.i("Wake word detected");
              }
              return;
            }

            // ===============================
            // TIMEOUT
            // ===============================

            if (DateTime.now().difference(_lastWakeTime).inSeconds > 10) {
              _wakeWordActivated = false;
              return;
            }

            // ===============================
            // DUPLICATE
            // ===============================

            if (text == _lastCommand) return;

            _lastCommand = text;

            // ===============================
            // EXECUTE (🔥 NEW ARCHITECTURE)
            // ===============================

            await _systemController.handleCommand(text);

            _wakeWordActivated = false;
          } catch (e) {
            _logger.e("Error in onResult: $e");
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      _logger.e("Start listening error: $e");
      _isListening = false;
    }
  }

  // =====================================
  // HANDLE CALL RESPONSE (Fallback)
  // =====================================

  Future<void> _handleCallResponse(String text) async {
    text = text.toLowerCase();

    if (text.contains("رد") || text.contains("answer")) {
      await _callControlChannel.invokeMethod('acceptCall');
      _logger.i("Call accepted via voice");
    }

    if (text.contains("ارفض") ||
        text.contains("اقفل") ||
        text.contains("reject")) {
      await _callControlChannel.invokeMethod('rejectCall');
      _logger.i("Call rejected via voice");
    }
  }

  // =====================================
  // RESTART
  // =====================================

  Future<void> _restartListening() async {
    if (_isRestarting) return;

    _isRestarting = true;

    await Future.delayed(const Duration(milliseconds: 300));

    _isRestarting = false;

    startListening();
  }

  // =====================================
  // STOP
  // =====================================

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      _logger.e("Stop listening error: $e");
    }
  }

  // =====================================
  // NORMALIZE
  // =====================================

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(",", "")
        .replaceAll(".", "")
        .replaceAll(RegExp(r'\s+'), " ");
  }
}

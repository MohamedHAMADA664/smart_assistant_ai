import '../services/voice_listener_service.dart';
import '../services/call_control_service.dart';
import '../services/voice_response_service.dart';

class SystemController {
  final VoiceListenerService _voiceListener = VoiceListenerService();
  final CallControlService _callControl = CallControlService();
  final VoiceResponseService _voice = VoiceResponseService();

  bool _isCallActive = false;

  // =========================
  // INIT
  // =========================

  Future<void> initialize() async {
    await _voiceListener.initialize();
  }

  // =========================
  // HANDLE COMMAND
  // =========================

  Future<void> handleCommand(String text) async {
    text = text.toLowerCase();

    // 🔥 CALL MODE
    if (_isCallActive) {
      await _handleCallCommand(text);
      return;
    }

    // 🔥 NORMAL MODE
    // هنا نسيب AIController يشتغل
  }

  // =========================
  // CALL COMMANDS
  // =========================

  Future<void> _handleCallCommand(String text) async {
    if (text.contains("رد")) {
      await _callControl.acceptCall();
      await _voice.speak("تم الرد على المكالمة");
      _isCallActive = false;
    }

    if (text.contains("ارفض") || text.contains("اقفل")) {
      await _callControl.rejectCall();
      await _voice.speak("تم رفض المكالمة");
      _isCallActive = false;
    }
  }

  // =========================
  // INCOMING CALL
  // =========================

  Future<void> onIncomingCall(String number) async {
    _isCallActive = true;

    await _voice.speak("مكالمة واردة، قل رد أو ارفض");
  }
}

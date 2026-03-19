import '../services/call_control_service.dart';
import '../services/voice_response_service.dart';

class SystemController {
  SystemController({
    CallControlService? callControlService,
    VoiceResponseService? voiceResponseService,
  })  : _callControl = callControlService ?? CallControlService(),
        _voice = voiceResponseService ?? VoiceResponseService();

  final CallControlService _callControl;
  final VoiceResponseService _voice;

  bool _isCallModeActive = false;

  bool get isCallModeActive => _isCallModeActive;

  // =========================
  // INIT
  // =========================

  Future<void> initialize() async {
    // Reserved for future app-level initialization if needed.
    // Do not initialize VoiceListenerService here to avoid circular dependency.
  }

  // =========================
  // HANDLE COMMAND
  // =========================

  Future<SystemCommandResult> handleCommand(String text) async {
    final normalizedText = _normalizeText(text);

    if (normalizedText.isEmpty) {
      return const SystemCommandResult.ignored();
    }

    if (_isCallModeActive) {
      return _handleCallCommand(normalizedText);
    }

    return const SystemCommandResult.notHandled();
  }

  // =========================
  // CALL COMMANDS
  // =========================

  Future<SystemCommandResult> _handleCallCommand(String text) async {
    if (_isAcceptCommand(text)) {
      await _callControl.acceptCall();
      await _voice.speak('تم الرد على المكالمة');
      _isCallModeActive = false;
      return const SystemCommandResult.handled('call_accepted');
    }

    if (_isRejectCommand(text)) {
      await _callControl.rejectCall();
      await _voice.speak('تم رفض المكالمة');
      _isCallModeActive = false;
      return const SystemCommandResult.handled('call_rejected');
    }

    return const SystemCommandResult.notHandled();
  }

  // =========================
  // INCOMING CALL
  // =========================

  Future<void> onIncomingCall(String number) async {
    _isCallModeActive = true;
    await _voice.speak('مكالمة واردة، قل رد أو ارفض');
  }

  // =========================
  // HELPERS
  // =========================

  String _normalizeText(String text) {
    return text.trim().toLowerCase();
  }

  bool _isAcceptCommand(String text) {
    return text.contains('رد') ||
        text.contains('اترد') ||
        text.contains('اقبل') ||
        text.contains('استقبل');
  }

  bool _isRejectCommand(String text) {
    return text.contains('ارفض') ||
        text.contains('رفض') ||
        text.contains('اقفل') ||
        text.contains('انهي') ||
        text.contains('سكر');
  }

  void resetCallMode() {
    _isCallModeActive = false;
  }
}

class SystemCommandResult {
  final bool handled;
  final String? action;

  const SystemCommandResult._({
    required this.handled,
    this.action,
  });

  const SystemCommandResult.handled(String action)
      : this._(handled: true, action: action);

  const SystemCommandResult.notHandled() : this._(handled: false);

  const SystemCommandResult.ignored() : this._(handled: false);
}

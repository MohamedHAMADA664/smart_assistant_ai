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
  String? _lastIncomingNumber;
  bool _isInitialized = false;

  bool get isCallModeActive => _isCallModeActive;

  // =========================
  // INIT
  // =========================

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _voice.initialize();
    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // =========================
  // HANDLE COMMAND
  // =========================

  Future<SystemCommandResult> handleCommand(String text) async {
    await _ensureInitialized();

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
      _lastIncomingNumber = null;
      return const SystemCommandResult.handled('call_accepted');
    }

    if (_isRejectCommand(text)) {
      await _callControl.rejectCall();
      await _voice.speak('تم رفض المكالمة');
      _isCallModeActive = false;
      _lastIncomingNumber = null;
      return const SystemCommandResult.handled('call_rejected');
    }

    await _voice.speak('قل رد أو ارفض');
    return const SystemCommandResult.notHandled();
  }

  // =========================
  // INCOMING CALL
  // =========================

  Future<void> onIncomingCall(String number) async {
    await _ensureInitialized();

    _isCallModeActive = true;
    _lastIncomingNumber = number.trim().isEmpty ? 'رقم غير معروف' : number.trim();

    await _voice.speak(
      'مكالمة واردة من $_lastIncomingNumber. قل رد أو ارفض',
    );
  }

  // =========================
  // HELPERS
  // =========================

  String _normalizeText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[،,.!?؟]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isAcceptCommand(String text) {
    return text.contains('رد') ||
        text.contains('اترد') ||
        text.contains('اقبل') ||
        text.contains('استقبل') ||
        text.contains('وافق') ||
        text.contains('answer') ||
        text.contains('accept');
  }

  bool _isRejectCommand(String text) {
    return text.contains('ارفض') ||
        text.contains('رفض') ||
        text.contains('اقفل') ||
        text.contains('انهي') ||
        text.contains('سكر') ||
        text.contains('reject') ||
        text.contains('decline');
  }

  void resetCallMode() {
    _isCallModeActive = false;
    _lastIncomingNumber = null;
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

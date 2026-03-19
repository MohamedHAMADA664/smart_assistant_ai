import 'voice_response_service.dart';

class NotificationReaderService {
  NotificationReaderService({
    VoiceResponseService? voiceResponseService,
  }) : _voice = voiceResponseService ?? VoiceResponseService();

  final VoiceResponseService _voice;

  // ================================
  // READ WHATSAPP MESSAGE
  // ================================

  Future<void> readWhatsAppMessage(String sender, String message) async {
    await readMessage(
      appName: 'واتساب',
      sender: sender,
      message: message,
    );
  }

  // ================================
  // READ GENERIC MESSAGE
  // ================================

  Future<void> readMessage({
    required String appName,
    required String sender,
    required String message,
  }) async {
    final normalizedAppName = _normalizeText(appName);
    final normalizedSender = _normalizeText(sender);
    final normalizedMessage = _normalizeText(message);

    if (normalizedSender.isEmpty || normalizedMessage.isEmpty) {
      return;
    }

    final speech = normalizedAppName.isEmpty
        ? 'وصلت رسالة من $normalizedSender. الرسالة تقول $normalizedMessage'
        : 'وصلت رسالة من $normalizedSender على $normalizedAppName. الرسالة تقول $normalizedMessage';

    await _voice.speak(speech);
  }

  // ================================
  // STOP READING
  // ================================

  Future<void> stop() async {
    await _voice.stop();
  }

  // ================================
  // HELPERS
  // ================================

  String _normalizeText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

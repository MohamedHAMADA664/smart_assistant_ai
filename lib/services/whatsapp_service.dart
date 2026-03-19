import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  // ================================
  // SEND MESSAGE
  // ================================

  Future<bool> sendMessage(String phone, String message) async {
    final normalizedPhone = _normalizePhone(phone);
    final normalizedMessage = message.trim();

    if (normalizedPhone.isEmpty || normalizedMessage.isEmpty) {
      return false;
    }

    final uri = Uri.parse(
      'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(normalizedMessage)}',
    );

    try {
      if (!await canLaunchUrl(uri)) {
        return false;
      }

      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  // ================================
  // OPEN CHAT ONLY
  // ================================

  Future<bool> openChat(String phone) async {
    final normalizedPhone = _normalizePhone(phone);

    if (normalizedPhone.isEmpty) {
      return false;
    }

    final uri = Uri.parse('https://wa.me/$normalizedPhone');

    try {
      if (!await canLaunchUrl(uri)) {
        return false;
      }

      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  // ================================
  // HELPERS
  // ================================

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

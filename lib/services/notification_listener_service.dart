import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NotificationListenerAI {
  final FlutterTts _tts = FlutterTts();

  String? _lastNotificationId;

  // ==========================
  // START LISTENING
  // ==========================

  void startListening() {
    NotificationListenerService.notificationsStream.listen((event) async {
      String? packageName = event.packageName;
      String? title = event.title;
      String? content = event.content;

      if (packageName == null) return;

      // منع قراءة نفس الإشعار مرتين

      String currentId = "$packageName$title$content";

      if (_lastNotificationId == currentId) {
        return;
      }

      _lastNotificationId = currentId;

      // تجاهل الإشعارات الفارغة

      if (title == null || title.isEmpty) return;
      if (content == null || content.isEmpty) return;

      // ==========================
      // WHATSAPP
      // ==========================

      if (packageName == "com.whatsapp") {
        await _announceMessage(
          "واتساب",
          title,
          content,
        );

        return;
      }

      // ==========================
      // MESSENGER
      // ==========================

      if (packageName == "com.facebook.orca") {
        await _announceMessage(
          "ماسنجر",
          title,
          content,
        );

        return;
      }

      // ==========================
      // TELEGRAM
      // ==========================

      if (packageName == "org.telegram.messenger") {
        await _announceMessage(
          "تيليجرام",
          title,
          content,
        );

        return;
      }
    });
  }

  // ==========================
  // ANNOUNCE MESSAGE
  // ==========================

  Future<void> _announceMessage(
    String app,
    String sender,
    String message,
  ) async {
    String speech = "لديك رسالة جديدة من $sender على $app";

    await _tts.setLanguage("ar");

    await _tts.setSpeechRate(0.45);

    await _tts.setPitch(1.0);

    await _tts.speak(speech);
  }
}

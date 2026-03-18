import 'package:flutter_tts/flutter_tts.dart';

class NotificationReaderService {
  final FlutterTts _tts = FlutterTts();

  Future<void> readWhatsAppMessage(String sender, String message) async {
    await _tts.setLanguage("ar-SA");

    String speech = "وصلت رسالة من $sender. الرسالة تقول $message";

    await _tts.speak(speech);
  }
}

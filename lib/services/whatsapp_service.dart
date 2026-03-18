import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  Future<void> sendMessage(String phone, String message) async {
    String url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

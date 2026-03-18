import 'package:url_launcher/url_launcher.dart';

class MusicService {
  // ================================
  // PLAY MUSIC (YouTube Search)
  // ================================

  Future<void> playMusic(String query) async {
    String searchUrl =
        "https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}";

    Uri uri = Uri.parse(searchUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Error opening music search");
    }
  }

  // ================================
  // 🔥 PLAY YOUTUBE (حل المشكلة)
  // ================================

  Future<void> playYoutube(String query) async {
    if (query.trim().isEmpty) {
      print("Empty YouTube query");
      return;
    }

    String searchUrl =
        "https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}";

    Uri uri = Uri.parse(searchUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Error opening YouTube");
    }
  }
}

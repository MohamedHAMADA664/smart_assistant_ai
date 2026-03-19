import 'package:url_launcher/url_launcher.dart';

class MusicService {
  // ================================
  // PLAY MUSIC
  // ================================

  Future<bool> playMusic(String query) async {
    final normalizedQuery = _normalizeQuery(query);

    if (normalizedQuery.isEmpty) {
      return false;
    }

    return _openYoutubeSearch(normalizedQuery);
  }

  // ================================
  // PLAY YOUTUBE
  // ================================

  Future<bool> playYoutube(String query) async {
    final normalizedQuery = _normalizeQuery(query);

    if (normalizedQuery.isEmpty) {
      return false;
    }

    return _openYoutubeSearch(normalizedQuery);
  }

  // ================================
  // HELPERS
  // ================================

  Future<bool> _openYoutubeSearch(String query) async {
    final uri = Uri.parse(
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
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

  String _normalizeQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

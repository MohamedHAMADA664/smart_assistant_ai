import '../models/intent_model.dart';

class OfflineAIBrain {
  // ===============================
  // INTENT TYPES
  // ===============================

  static const String openApp = 'open_app';
  static const String callContact = 'call_contact';
  static const String playMusic = 'play_music';
  static const String youtubeSearch = 'youtube_search';
  static const String webSearch = 'web_search';
  static const String wifiControl = 'wifi_control';
  static const String bluetoothControl = 'bluetooth_control';
  static const String volumeControl = 'volume_control';
  static const String cameraControl = 'camera_control';
  static const String greeting = 'greeting';
  static const String acceptCall = 'accept_call';
  static const String rejectCall = 'reject_call';
  static const String unknown = 'unknown';

  static const Map<String, String> _knownApps = {
    'واتساب': 'whatsapp',
    'whatsapp': 'whatsapp',
    'يوتيوب': 'youtube',
    'youtube': 'youtube',
    'فيسبوك': 'facebook',
    'facebook': 'facebook',
    'انستجرام': 'instagram',
    'instagram': 'instagram',
    'تيك توك': 'tiktok',
    'tiktok': 'tiktok',
    'جوجل': 'google',
    'google': 'google',
    'كروم': 'chrome',
    'chrome': 'chrome',
  };

  static const List<String> _commandSplitters = [
    ' بعد كده ',
    ' بعدها ',
    ' ثم ',
    ' and ',
    ' then ',
    ' و ',
  ];

  static const List<String> _callAcceptKeywords = [
    'رد',
    'اترد',
    'اقبل',
    'استقبل',
    'accept',
    'answer',
  ];

  static const List<String> _callRejectKeywords = [
    'ارفض',
    'رفض',
    'اقفل',
    'انهي',
    'سكر',
    'reject',
    'decline',
  ];

  static const List<String> _greetingKeywords = [
    'اهلا',
    'أهلا',
    'مرحبا',
    'ازيك',
    'عامل ايه',
    'hello',
    'hi',
  ];

  static const List<String> _callKeywords = [
    'اتصل',
    'كلم',
    'اتصال',
    'call',
    'dial',
    'phone',
  ];

  static const List<String> _youtubeKeywords = [
    'يوتيوب',
    'youtube',
    'فيديو',
    'video',
  ];

  static const List<String> _webSearchKeywords = [
    'ابحث',
    'دور',
    'search',
    'google',
    'جوجل',
  ];

  static const List<String> _musicKeywords = [
    'اغاني',
    'أغاني',
    'موسيقى',
    'اسمع',
    'شغل اغنية',
    'شغل أغنية',
    'music',
    'song',
    'songs',
  ];

  static const List<String> _wifiKeywords = [
    'واي فاي',
    'wifi',
    'wi-fi',
  ];

  static const List<String> _bluetoothKeywords = [
    'بلوتوث',
    'bluetooth',
  ];

  static const List<String> _volumeKeywords = [
    'الصوت',
    'volume',
    'mute',
    'وطي',
    'علي الصوت',
    'خفض الصوت',
    'ارفع الصوت',
    'اكتم',
  ];

  static const List<String> _cameraKeywords = [
    'كاميرا',
    'صور',
    'افتح الكاميرا',
    'camera',
    'photo',
    'take photo',
  ];

  static const List<String> _openAppKeywords = [
    'افتح',
    'شغل',
    'ابدأ',
    'open',
    'launch',
    'run',
  ];

  // ===============================
  // MAIN ANALYZE FUNCTION
  // ===============================

  List<IntentModel> analyze(String text) {
    final cleanText = _normalize(text);
    if (cleanText.isEmpty) {
      return const [];
    }

    final commands = _splitCommands(cleanText);
    final intents = <IntentModel>[];

    for (final command in commands) {
      if (command.trim().isEmpty) {
        continue;
      }

      final action = detectIntent(command);

      intents.add(
        IntentModel(
          action: action,
          appName: _extractAppName(command, action),
          contactName: _extractContactName(command, action),
          query: _extractQuery(command, action),
        ),
      );
    }

    return intents;
  }

  // ===============================
  // DETECT INTENT
  // ===============================

  String detectIntent(String text) {
    final normalized = _normalize(text);

    if (normalized.isEmpty) {
      return unknown;
    }

    if (_matchesAnyKeyword(normalized, _callAcceptKeywords)) {
      return acceptCall;
    }

    if (_matchesAnyKeyword(normalized, _callRejectKeywords)) {
      return rejectCall;
    }

    if (_matchesAnyKeyword(normalized, _greetingKeywords)) {
      return greeting;
    }

    if (_matchesAnyKeyword(normalized, _callKeywords)) {
      return callContact;
    }

    if (_matchesAnyKeyword(normalized, _youtubeKeywords)) {
      return youtubeSearch;
    }

    if (_matchesAnyKeyword(normalized, _musicKeywords)) {
      return playMusic;
    }

    if (_matchesAnyKeyword(normalized, _wifiKeywords)) {
      return wifiControl;
    }

    if (_matchesAnyKeyword(normalized, _bluetoothKeywords)) {
      return bluetoothControl;
    }

    if (_matchesAnyKeyword(normalized, _volumeKeywords)) {
      return volumeControl;
    }

    if (_matchesAnyKeyword(normalized, _cameraKeywords)) {
      return cameraControl;
    }

    if (_matchesAnyKeyword(normalized, _webSearchKeywords)) {
      return webSearch;
    }

    if (_matchesAnyKeyword(normalized, _openAppKeywords) ||
        _extractAppName(normalized, openApp) != null) {
      return openApp;
    }

    return unknown;
  }

  // ===============================
  // SPLIT MULTIPLE COMMANDS
  // ===============================

  List<String> _splitCommands(String text) {
    var result = text;

    for (final splitter in _commandSplitters) {
      result = result.replaceAll(splitter, '|');
    }

    return result
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  // ===============================
  // EXTRACT APP NAME
  // ===============================

  String? _extractAppName(String text, String action) {
    if (action != openApp && action != youtubeSearch) {
      return null;
    }

    for (final entry in _knownApps.entries) {
      if (_containsPhrase(text, entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  // ===============================
  // EXTRACT CONTACT NAME
  // ===============================

  String? _extractContactName(String text, String action) {
    if (action != callContact) {
      return null;
    }

    final cleaned = _removeLeadingKeywords(
      text,
      _callKeywords,
    );

    final result = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  // ===============================
  // EXTRACT QUERY
  // ===============================

  String? _extractQuery(String text, String action) {
    switch (action) {
      case youtubeSearch:
        final youtubeQuery = _removeLeadingKeywords(
          text,
          [
            ..._youtubeKeywords,
            'شغل',
            'افتح',
            'دور',
            'ابحث',
            'عن',
            'video',
          ],
        ).trim();
        return youtubeQuery.isEmpty ? null : youtubeQuery;

      case webSearch:
        final searchQuery = _removeLeadingKeywords(
          text,
          [
            ..._webSearchKeywords,
            'عن',
          ],
        ).trim();
        return searchQuery.isEmpty ? null : searchQuery;

      case playMusic:
        final musicQuery = _removeLeadingKeywords(
          text,
          [
            ..._musicKeywords,
            'شغل',
            'افتح',
            'اسمع',
            'عن',
          ],
        ).trim();
        return musicQuery.isEmpty ? null : musicQuery;

      default:
        return null;
    }
  }

  // ===============================
  // HELPERS
  // ===============================

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('لو سمحت', ' ')
        .replaceAll('من فضلك', ' ')
        .replaceAll('ممكن', ' ')
        .replaceAll('please', ' ')
        .replaceAll(RegExp(r'[،,.!?؟]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _matchesAnyKeyword(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (_containsPhrase(text, keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool _containsPhrase(String text, String phrase) {
    final normalizedText = ' ${_normalize(text)} ';
    final normalizedPhrase = ' ${_normalize(phrase)} ';
    return normalizedText.contains(normalizedPhrase);
  }

  String _removeLeadingKeywords(String text, List<String> keywords) {
    var result = _normalize(text);

    for (final keyword in keywords) {
      final normalizedKeyword = _normalize(keyword);

      if (result.startsWith('$normalizedKeyword ')) {
        result = result.substring(normalizedKeyword.length).trim();
      }
    }

    return result;
  }
}

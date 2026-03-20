import '../services/assistant_profile_service.dart';

class WakeWordService {
  WakeWordService({
    AssistantProfileService? assistantProfileService,
  }) : _assistantProfileService =
            assistantProfileService ?? AssistantProfileService();

  final AssistantProfileService _assistantProfileService;

  String _assistantName = 'مساعدي';
  String _wakeWord = 'يا مساعدي';

  final List<String> _defaultWakeWords = [
    'يا مساعد',
    'مساعد',
    'يا مساعدي',
    'مساعدي',
    'hey assistant',
    'ok assistant',
    'assistant',
    'siri',
    'يا siri',
    'nada',
    'يا nada',
  ];

  final List<String> _customWakeWords = [];

  bool _initialized = false;

  String get assistantName => _assistantName;
  String get wakeWord => _wakeWord;

  List<String> get activeWakeWords {
    final words = <String>{
      ..._defaultWakeWords.map(_normalize),
      ..._buildAssistantNameWakeWords(_assistantName).map(_normalize),
      ..._buildWakeWordVariants(_wakeWord).map(_normalize),
      ..._customWakeWords.map(_normalize),
    };

    words.removeWhere((word) => word.trim().isEmpty);
    return words.toList()..sort((a, b) => b.length.compareTo(a.length));
  }

  // =================================
  // INITIALIZE
  // =================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      final profile = await _assistantProfileService.loadProfile();

      final normalizedAssistantName = _normalize(profile.assistantName);
      final normalizedWakeWord = _normalize(profile.wakeWord);

      _assistantName =
          normalizedAssistantName.isEmpty ? 'مساعدي' : normalizedAssistantName;
      _wakeWord = normalizedWakeWord.isEmpty ? 'يا مساعدي' : normalizedWakeWord;
      _initialized = true;
    } catch (_) {
      _assistantName = 'مساعدي';
      _wakeWord = 'يا مساعدي';
      _initialized = true;
    }
  }

  // =================================
  // DETECT WAKE WORD
  // =================================

  bool detectWakeWord(String speechText) {
    final normalizedSpeechText = _normalize(speechText);

    if (normalizedSpeechText.isEmpty) {
      return false;
    }

    final compactSpeechText = _compact(normalizedSpeechText);

    for (final word in activeWakeWords) {
      if (word.isEmpty) {
        continue;
      }

      if (_containsPhrase(normalizedSpeechText, word)) {
        return true;
      }

      final withoutYa = _removeLeadingYa(word);
      if (withoutYa.isNotEmpty &&
          _containsPhrase(normalizedSpeechText, withoutYa)) {
        return true;
      }

      if (_compact(word).isNotEmpty &&
          compactSpeechText.contains(_compact(word))) {
        return true;
      }

      if (withoutYa.isNotEmpty &&
          _compact(withoutYa).isNotEmpty &&
          compactSpeechText.contains(_compact(withoutYa))) {
        return true;
      }
    }

    final normalizedAssistantName = _normalize(_assistantName);
    if (normalizedAssistantName.isNotEmpty) {
      if (_containsPhrase(normalizedSpeechText, normalizedAssistantName)) {
        return true;
      }

      final compactAssistantName = _compact(normalizedAssistantName);
      if (compactAssistantName.isNotEmpty &&
          compactSpeechText.contains(compactAssistantName)) {
        return true;
      }
    }

    return false;
  }

  // =================================
  // SET NEW WAKE WORD
  // =================================

  Future<void> setWakeWord(String newWord) async {
    final normalizedWord = _normalize(newWord);

    if (normalizedWord.isEmpty) {
      return;
    }

    final profile = await _assistantProfileService.loadProfile();
    final updatedProfile = profile.copyWith(
      wakeWord: normalizedWord,
    );

    await _assistantProfileService.saveProfile(updatedProfile);
    _wakeWord = normalizedWord;
  }

  // =================================
  // SET ASSISTANT NAME
  // =================================

  Future<void> setAssistantName(String newName) async {
    final normalizedName = _normalize(newName);

    if (normalizedName.isEmpty) {
      return;
    }

    final profile = await _assistantProfileService.loadProfile();
    final updatedProfile = profile.copyWith(
      assistantName: normalizedName,
    );

    await _assistantProfileService.saveProfile(updatedProfile);
    _assistantName = normalizedName;
  }

  // =================================
  // ADD CUSTOM WAKE WORD
  // =================================

  void addCustomWakeWord(String word) {
    final normalizedWord = _normalize(word);

    if (normalizedWord.isEmpty) {
      return;
    }

    if (!_customWakeWords.contains(normalizedWord)) {
      _customWakeWords.add(normalizedWord);
    }
  }

  // =================================
  // REMOVE CUSTOM WAKE WORD
  // =================================

  void removeCustomWakeWord(String word) {
    final normalizedWord = _normalize(word);

    if (normalizedWord.isEmpty) {
      return;
    }

    _customWakeWords.remove(normalizedWord);
  }

  // =================================
  // GET CURRENT VALUES
  // =================================

  String getWakeWord() {
    return _wakeWord;
  }

  String getAssistantName() {
    return _assistantName;
  }

  // =================================
  // HELPERS
  // =================================

  List<String> _buildAssistantNameWakeWords(String assistantName) {
    final normalizedName = _normalize(assistantName);

    if (normalizedName.isEmpty) {
      return const <String>[];
    }

    return <String>[
      normalizedName,
      'يا $normalizedName',
      'hey $normalizedName',
      'ok $normalizedName',
    ];
  }

  List<String> _buildWakeWordVariants(String wakeWord) {
    final normalizedWakeWord = _normalize(wakeWord);

    if (normalizedWakeWord.isEmpty) {
      return const <String>[];
    }

    final variants = <String>{
      normalizedWakeWord,
      _removeLeadingYa(normalizedWakeWord),
    };

    if (!normalizedWakeWord.startsWith('يا ')) {
      variants.add('يا $normalizedWakeWord');
    }

    final normalizedAssistantName = _normalize(_assistantName);
    if (normalizedAssistantName.isNotEmpty) {
      variants.add(normalizedAssistantName);
      variants.add('يا $normalizedAssistantName');
    }

    variants.removeWhere((word) => word.trim().isEmpty);
    return variants.toList();
  }

  bool _containsPhrase(String text, String phrase) {
    final normalizedText = ' ${_normalize(text)} ';
    final normalizedPhrase = ' ${_normalize(phrase)} ';

    if (normalizedPhrase.trim().isEmpty) {
      return false;
    }

    if (normalizedText.contains(normalizedPhrase)) {
      return true;
    }

    final phraseWithoutYa = _removeLeadingYa(normalizedPhrase.trim());
    if (phraseWithoutYa.isNotEmpty &&
        normalizedText.contains(' $phraseWithoutYa ')) {
      return true;
    }

    return false;
  }

  String _removeLeadingYa(String text) {
    final normalized = _normalize(text);

    if (normalized.startsWith('يا ')) {
      return normalized.substring(3).trim();
    }

    return normalized;
  }

  String _compact(String text) {
    return _normalize(text).replaceAll(' ', '');
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

import '../services/settings_service.dart';

class WakeWordService {
  String _wakeWord = "مساعد";

  final List<String> _defaultWakeWords = [
    "يا مساعد",
    "مساعد",
    "hey assistant",
    "ok assistant",
    "assistant",
  ];

  final List<String> _customWakeWords = [];

  // =================================
  // INITIALIZE
  // =================================

  Future<void> initialize() async {
    try {
      String savedWord = await SettingsService.getWakeWord();

      if (savedWord.isNotEmpty) {
        _wakeWord = _normalize(savedWord);
      }
    } catch (e) {
      _wakeWord = "مساعد";
    }
  }

  // =================================
  // DETECT WAKE WORD
  // =================================

  bool detectWakeWord(String speechText) {
    speechText = _normalize(speechText);

    // Check main wake word

    if (speechText.contains(_wakeWord)) {
      return true;
    }

    // Check default wake words

    for (String word in _defaultWakeWords) {
      if (speechText.contains(_normalize(word))) {
        return true;
      }
    }

    // Check custom wake words

    for (String word in _customWakeWords) {
      if (speechText.contains(_normalize(word))) {
        return true;
      }
    }

    return false;
  }

  // =================================
  // SET NEW WAKE WORD
  // =================================

  Future<void> setWakeWord(String newWord) async {
    if (newWord.trim().isEmpty) return;

    _wakeWord = _normalize(newWord);

    await SettingsService.saveWakeWord(_wakeWord);
  }

  // =================================
  // ADD CUSTOM WAKE WORD
  // =================================

  void addCustomWakeWord(String word) {
    word = _normalize(word);

    if (!_customWakeWords.contains(word)) {
      _customWakeWords.add(word);
    }
  }

  // =================================
  // REMOVE CUSTOM WAKE WORD
  // =================================

  void removeCustomWakeWord(String word) {
    word = _normalize(word);

    _customWakeWords.remove(word);
  }

  // =================================
  // GET CURRENT WAKE WORD
  // =================================

  String getWakeWord() {
    return _wakeWord;
  }

  // =================================
  // NORMALIZE TEXT
  // =================================

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll("  ", " ")
        .replaceAll(",", "")
        .replaceAll(".", "");
  }
}

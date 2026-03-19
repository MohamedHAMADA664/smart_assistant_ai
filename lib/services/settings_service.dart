import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String wakeWordKey = 'wake_word';
  static const String assistantNameKey = 'assistant_name';
  static const String voiceLanguageKey = 'voice_language';
  static const String speechRateKey = 'speech_rate';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String onlineAiEnabledKey = 'online_ai_enabled';
  static const String backgroundModeEnabledKey = 'background_mode_enabled';

  static const String _defaultWakeWord = 'يا مساعدي';
  static const String _defaultAssistantName = 'مساعدي';
  static const String _defaultVoiceLanguage = 'ar';
  static const double _defaultSpeechRate = 0.5;
  static const bool _defaultNotificationsEnabled = true;
  static const bool _defaultOnlineAiEnabled = false;
  static const bool _defaultBackgroundModeEnabled = true;

  SharedPreferences? _prefs;
  bool _initialized = false;

  // ================================
  // INITIALIZE
  // ================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ================================
  // WAKE WORD
  // ================================

  Future<void> saveWakeWord(String word) async {
    await _ensureInitialized();

    final normalizedWord = _normalizeText(word);
    await _prefs!.setString(wakeWordKey, normalizedWord);
  }

  Future<String> getWakeWord() async {
    await _ensureInitialized();

    final storedWord = _prefs!.getString(wakeWordKey);
    final normalizedWord = _normalizeText(storedWord);

    if (normalizedWord.isEmpty) {
      return _defaultWakeWord;
    }

    return normalizedWord;
  }

  Future<void> resetWakeWord() async {
    await _ensureInitialized();
    await _prefs!.remove(wakeWordKey);
  }

  // ================================
  // ASSISTANT NAME
  // ================================

  Future<void> saveAssistantName(String name) async {
    await _ensureInitialized();

    final normalizedName = _normalizeText(name);
    await _prefs!.setString(assistantNameKey, normalizedName);
  }

  Future<String> getAssistantName() async {
    await _ensureInitialized();

    final storedName = _prefs!.getString(assistantNameKey);
    final normalizedName = _normalizeText(storedName);

    if (normalizedName.isEmpty) {
      return _defaultAssistantName;
    }

    return normalizedName;
  }

  Future<void> resetAssistantName() async {
    await _ensureInitialized();
    await _prefs!.remove(assistantNameKey);
  }

  // ================================
  // VOICE LANGUAGE
  // ================================

  Future<void> saveVoiceLanguage(String languageCode) async {
    await _ensureInitialized();

    final normalizedLanguage = _normalizeText(languageCode);
    if (normalizedLanguage.isEmpty) {
      return;
    }

    await _prefs!.setString(voiceLanguageKey, normalizedLanguage);
  }

  Future<String> getVoiceLanguage() async {
    await _ensureInitialized();

    final storedLanguage = _prefs!.getString(voiceLanguageKey);
    final normalizedLanguage = _normalizeText(storedLanguage);

    if (normalizedLanguage.isEmpty) {
      return _defaultVoiceLanguage;
    }

    return normalizedLanguage;
  }

  // ================================
  // SPEECH RATE
  // ================================

  Future<void> saveSpeechRate(double rate) async {
    await _ensureInitialized();

    final normalizedRate = rate.clamp(0.1, 1.0);
    await _prefs!.setDouble(speechRateKey, normalizedRate);
  }

  Future<double> getSpeechRate() async {
    await _ensureInitialized();

    return _prefs!.getDouble(speechRateKey) ?? _defaultSpeechRate;
  }

  // ================================
  // NOTIFICATIONS
  // ================================

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(notificationsEnabledKey, enabled);
  }

  Future<bool> isNotificationsEnabled() async {
    await _ensureInitialized();

    return _prefs!.getBool(notificationsEnabledKey) ??
        _defaultNotificationsEnabled;
  }

  // ================================
  // ONLINE AI
  // ================================

  Future<void> setOnlineAiEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(onlineAiEnabledKey, enabled);
  }

  Future<bool> isOnlineAiEnabled() async {
    await _ensureInitialized();

    return _prefs!.getBool(onlineAiEnabledKey) ?? _defaultOnlineAiEnabled;
  }

  // ================================
  // BACKGROUND MODE
  // ================================

  Future<void> setBackgroundModeEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(backgroundModeEnabledKey, enabled);
  }

  Future<bool> isBackgroundModeEnabled() async {
    await _ensureInitialized();

    return _prefs!.getBool(backgroundModeEnabledKey) ??
        _defaultBackgroundModeEnabled;
  }

  // ================================
  // RESET ALL SETTINGS
  // ================================

  Future<void> resetAllSettings() async {
    await _ensureInitialized();

    await _prefs!.remove(wakeWordKey);
    await _prefs!.remove(assistantNameKey);
    await _prefs!.remove(voiceLanguageKey);
    await _prefs!.remove(speechRateKey);
    await _prefs!.remove(notificationsEnabledKey);
    await _prefs!.remove(onlineAiEnabledKey);
    await _prefs!.remove(backgroundModeEnabledKey);
  }

  // ================================
  // HELPERS
  // ================================

  String _normalizeText(String? text) {
    return (text ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

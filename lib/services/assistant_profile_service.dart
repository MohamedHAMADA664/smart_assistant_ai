import 'settings_service.dart';

class AssistantProfileService {
  AssistantProfileService({
    SettingsService? settingsService,
  }) : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;

  static const String _defaultAssistantName = 'مساعدي';
  static const String _defaultWakeWord = 'يا مساعدي';
  static const String _defaultVoiceLanguage = 'ar';
  static const double _defaultSpeechRate = 0.5;

  // ================================
  // LOAD PROFILE
  // ================================

  Future<AssistantProfile> loadProfile() async {
    await _settingsService.initialize();

    final assistantName = await _settingsService.getAssistantName();
    final wakeWord = await _settingsService.getWakeWord();
    final voiceLanguage = await _settingsService.getVoiceLanguage();
    final speechRate = await _settingsService.getSpeechRate();
    final notificationsEnabled =
        await _settingsService.isNotificationsEnabled();
    final onlineAiEnabled = await _settingsService.isOnlineAiEnabled();
    final backgroundModeEnabled =
        await _settingsService.isBackgroundModeEnabled();

    return AssistantProfile(
      assistantName: _sanitizeAssistantName(assistantName),
      wakeWord: _sanitizeWakeWord(wakeWord),
      voiceLanguage: _sanitizeVoiceLanguage(voiceLanguage),
      speechRate: _sanitizeSpeechRate(speechRate),
      notificationsEnabled: notificationsEnabled,
      onlineAiEnabled: onlineAiEnabled,
      backgroundModeEnabled: backgroundModeEnabled,
    );
  }

  // ================================
  // SAVE PROFILE
  // ================================

  Future<void> saveProfile(AssistantProfile profile) async {
    await _settingsService.initialize();

    final normalizedProfile = profile.normalized(
      defaultAssistantName: _defaultAssistantName,
      defaultWakeWord: _defaultWakeWord,
      defaultVoiceLanguage: _defaultVoiceLanguage,
      defaultSpeechRate: _defaultSpeechRate,
    );

    await _settingsService.saveAssistantName(normalizedProfile.assistantName);
    await _settingsService.saveWakeWord(normalizedProfile.wakeWord);
    await _settingsService.saveVoiceLanguage(normalizedProfile.voiceLanguage);
    await _settingsService.saveSpeechRate(normalizedProfile.speechRate);
    await _settingsService
        .setNotificationsEnabled(normalizedProfile.notificationsEnabled);
    await _settingsService.setOnlineAiEnabled(normalizedProfile.onlineAiEnabled);
    await _settingsService
        .setBackgroundModeEnabled(normalizedProfile.backgroundModeEnabled);
  }

  // ================================
  // QUICK UPDATE HELPERS
  // ================================

  Future<void> updateAssistantName(String assistantName) async {
    await _settingsService.initialize();
    await _settingsService.saveAssistantName(
      _sanitizeAssistantName(assistantName),
    );
  }

  Future<void> updateWakeWord(String wakeWord) async {
    await _settingsService.initialize();
    await _settingsService.saveWakeWord(
      _sanitizeWakeWord(wakeWord),
    );
  }

  Future<void> updateVoiceLanguage(String voiceLanguage) async {
    await _settingsService.initialize();
    await _settingsService.saveVoiceLanguage(
      _sanitizeVoiceLanguage(voiceLanguage),
    );
  }

  Future<void> updateSpeechRate(double speechRate) async {
    await _settingsService.initialize();
    await _settingsService.saveSpeechRate(
      _sanitizeSpeechRate(speechRate),
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsService.initialize();
    await _settingsService.setNotificationsEnabled(enabled);
  }

  Future<void> setOnlineAiEnabled(bool enabled) async {
    await _settingsService.initialize();
    await _settingsService.setOnlineAiEnabled(enabled);
  }

  Future<void> setBackgroundModeEnabled(bool enabled) async {
    await _settingsService.initialize();
    await _settingsService.setBackgroundModeEnabled(enabled);
  }

  // ================================
  // RESET
  // ================================

  Future<AssistantProfile> resetProfile() async {
    await _settingsService.initialize();
    await _settingsService.resetAllSettings();
    return loadProfile();
  }

  // ================================
  // HELPERS
  // ================================

  String _sanitizeAssistantName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return _defaultAssistantName;
    }

    return normalized;
  }

  String _sanitizeWakeWord(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return _defaultWakeWord;
    }

    return normalized;
  }

  String _sanitizeVoiceLanguage(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'ar' || normalized == 'en') {
      return normalized;
    }

    return _defaultVoiceLanguage;
  }

  double _sanitizeSpeechRate(double value) {
    return value.clamp(0.1, 1.0).toDouble();
  }
}

class AssistantProfile {
  const AssistantProfile({
    required this.assistantName,
    required this.wakeWord,
    required this.voiceLanguage,
    required this.speechRate,
    required this.notificationsEnabled,
    required this.onlineAiEnabled,
    required this.backgroundModeEnabled,
  });

  final String assistantName;
  final String wakeWord;
  final String voiceLanguage;
  final double speechRate;
  final bool notificationsEnabled;
  final bool onlineAiEnabled;
  final bool backgroundModeEnabled;

  AssistantProfile copyWith({
    String? assistantName,
    String? wakeWord,
    String? voiceLanguage,
    double? speechRate,
    bool? notificationsEnabled,
    bool? onlineAiEnabled,
    bool? backgroundModeEnabled,
  }) {
    return AssistantProfile(
      assistantName: assistantName ?? this.assistantName,
      wakeWord: wakeWord ?? this.wakeWord,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      speechRate: speechRate ?? this.speechRate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onlineAiEnabled: onlineAiEnabled ?? this.onlineAiEnabled,
      backgroundModeEnabled:
          backgroundModeEnabled ?? this.backgroundModeEnabled,
    );
  }

  AssistantProfile normalized({
    required String defaultAssistantName,
    required String defaultWakeWord,
    required String defaultVoiceLanguage,
    required double defaultSpeechRate,
  }) {
    final normalizedAssistantName =
        assistantName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedWakeWord = wakeWord.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedVoiceLanguage = voiceLanguage.trim().toLowerCase();

    return AssistantProfile(
      assistantName: normalizedAssistantName.isEmpty
          ? defaultAssistantName
          : normalizedAssistantName,
      wakeWord: normalizedWakeWord.isEmpty ? defaultWakeWord : normalizedWakeWord,
      voiceLanguage:
          normalizedVoiceLanguage == 'ar' || normalizedVoiceLanguage == 'en'
              ? normalizedVoiceLanguage
              : defaultVoiceLanguage,
      speechRate: speechRate.clamp(0.1, 1.0).toDouble(),
      notificationsEnabled: notificationsEnabled,
      onlineAiEnabled: onlineAiEnabled,
      backgroundModeEnabled: backgroundModeEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assistantName': assistantName,
      'wakeWord': wakeWord,
      'voiceLanguage': voiceLanguage,
      'speechRate': speechRate,
      'notificationsEnabled': notificationsEnabled,
      'onlineAiEnabled': onlineAiEnabled,
      'backgroundModeEnabled': backgroundModeEnabled,
    };
  }

  @override
  String toString() {
    return 'AssistantProfile('
        'assistantName: $assistantName, '
        'wakeWord: $wakeWord, '
        'voiceLanguage: $voiceLanguage, '
        'speechRate: $speechRate, '
        'notificationsEnabled: $notificationsEnabled, '
        'onlineAiEnabled: $onlineAiEnabled, '
        'backgroundModeEnabled: $backgroundModeEnabled'
        ')';
  }
}

import 'settings_service.dart';

class AssistantProfileService {
  AssistantProfileService({
    SettingsService? settingsService,
  }) : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;

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
      assistantName: assistantName,
      wakeWord: wakeWord,
      voiceLanguage: voiceLanguage,
      speechRate: speechRate,
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

    await _settingsService.saveAssistantName(profile.assistantName);
    await _settingsService.saveWakeWord(profile.wakeWord);
    await _settingsService.saveVoiceLanguage(profile.voiceLanguage);
    await _settingsService.saveSpeechRate(profile.speechRate);
    await _settingsService
        .setNotificationsEnabled(profile.notificationsEnabled);
    await _settingsService.setOnlineAiEnabled(profile.onlineAiEnabled);
    await _settingsService
        .setBackgroundModeEnabled(profile.backgroundModeEnabled);
  }

  // ================================
  // QUICK UPDATE HELPERS
  // ================================

  Future<void> updateAssistantName(String assistantName) async {
    await _settingsService.saveAssistantName(assistantName);
  }

  Future<void> updateWakeWord(String wakeWord) async {
    await _settingsService.saveWakeWord(wakeWord);
  }

  Future<void> updateVoiceLanguage(String voiceLanguage) async {
    await _settingsService.saveVoiceLanguage(voiceLanguage);
  }

  Future<void> updateSpeechRate(double speechRate) async {
    await _settingsService.saveSpeechRate(speechRate);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsService.setNotificationsEnabled(enabled);
  }

  Future<void> setOnlineAiEnabled(bool enabled) async {
    await _settingsService.setOnlineAiEnabled(enabled);
  }

  Future<void> setBackgroundModeEnabled(bool enabled) async {
    await _settingsService.setBackgroundModeEnabled(enabled);
  }

  // ================================
  // RESET
  // ================================

  Future<AssistantProfile> resetProfile() async {
    await _settingsService.resetAllSettings();
    return loadProfile();
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

import 'package:flutter_tts/flutter_tts.dart';

import 'assistant_profile_service.dart';

class VoiceResponseService {
  VoiceResponseService({
    FlutterTts? flutterTts,
    AssistantProfileService? assistantProfileService,
    double pitch = 1.0,
  })  : _tts = flutterTts ?? FlutterTts(),
        _assistantProfileService =
            assistantProfileService ?? AssistantProfileService(),
        _defaultPitch = pitch;

  final FlutterTts _tts;
  final AssistantProfileService _assistantProfileService;
  final double _defaultPitch;

  bool _initialized = false;
  bool _isSpeaking = false;

  String _currentLanguage = 'ar';
  double _currentSpeechRate = 0.5;

  bool get isInitialized => _initialized;
  bool get isSpeaking => _isSpeaking;
  String get currentLanguage => _currentLanguage;
  double get currentSpeechRate => _currentSpeechRate;

  // ================================
  // INITIALIZE TTS
  // ================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _loadProfileSettings();
    await _applyCurrentSettings();

    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      _isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
    });

    _tts.setErrorHandler((_) {
      _isSpeaking = false;
    });

    _initialized = true;
  }

  // ================================
  // REFRESH SETTINGS
  // ================================

  Future<void> refreshSettings() async {
    if (!_initialized) {
      await initialize();
      return;
    }

    await _loadProfileSettings();
    await _applyCurrentSettings();
  }

  // ================================
  // SPEAK TEXT
  // ================================

  Future<void> speak(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      await _applyCurrentSettings();
      await _tts.stop();
      await _tts.speak(normalizedText);
    } catch (_) {
      _isSpeaking = false;
    }
  }

  // ================================
  // STOP SPEAKING
  // ================================

  Future<void> stop() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await _tts.stop();
    } finally {
      _isSpeaking = false;
    }
  }

  // ================================
  // CHANGE LANGUAGE
  // ================================

  Future<void> setLanguage(String languageCode) async {
    final normalizedLanguage = languageCode.trim();
    if (normalizedLanguage.isEmpty) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    _currentLanguage = normalizedLanguage;
    await _tts.setLanguage(_currentLanguage);
  }

  // ================================
  // CHANGE SPEECH RATE
  // ================================

  Future<void> setSpeechRate(double speechRate) async {
    if (!_initialized) {
      await initialize();
    }

    _currentSpeechRate = speechRate.clamp(0.1, 1.0).toDouble();
    await _tts.setSpeechRate(_currentSpeechRate);
  }

  // ================================
  // DISPOSE
  // ================================

  Future<void> dispose() async {
    await stop();
  }

  // ================================
  // INTERNAL HELPERS
  // ================================

  Future<void> _loadProfileSettings() async {
    try {
      final profile = await _assistantProfileService.loadProfile();

      final language = profile.voiceLanguage.trim();
      _currentLanguage = language.isEmpty ? 'ar' : language;

      _currentSpeechRate = profile.speechRate.clamp(0.1, 1.0).toDouble();
    } catch (_) {
      _currentLanguage = 'ar';
      _currentSpeechRate = 0.5;
    }
  }

  Future<void> _applyCurrentSettings() async {
    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(_currentSpeechRate);
    await _tts.setPitch(_defaultPitch);
  }
}

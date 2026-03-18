import 'package:flutter_tts/flutter_tts.dart';

class VoiceResponseService {
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  // ================================
  // INITIALIZE TTS
  // ================================

  Future<void> initialize() async {
    if (_initialized) return;

    await _tts.setLanguage("ar");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    _initialized = true;
  }

  // ================================
  // SPEAK TEXT
  // ================================

  Future<void> speak(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    await _tts.stop();
    await _tts.speak(text);
  }

  // ================================
  // STOP SPEAKING
  // ================================

  Future<void> stop() async {
    await _tts.stop();
  }
}

import 'offline_ai_brain.dart';
import 'command_engine.dart';
import '../services/voice_response_service.dart';
import '../models/intent_model.dart';

class AIController {
  final OfflineAIBrain _brain = OfflineAIBrain();
  final CommandEngine _engine = CommandEngine();
  final VoiceResponseService _voice = VoiceResponseService();

  // =================================
  // MAIN VOICE INPUT
  // =================================

  Future<void> processVoice(String speechText) async {
    if (speechText.trim().isEmpty) {
      return;
    }

    String cleanText = _normalize(speechText);

    // =================================
    // ANALYZE → LIST OF INTENTS
    // =================================

    List<IntentModel> intents = _brain.analyze(cleanText);

    // =================================
    // EXECUTE EACH INTENT
    // =================================

    for (IntentModel intent in intents) {
      await _handleIntent(intent);
    }
  }

  // =================================
  // HANDLE INTENT
  // =================================

  Future<void> _handleIntent(IntentModel intent) async {
    switch (intent.action) {
      // =================================
      // GREETING
      // =================================

      case OfflineAIBrain.greeting:
        await _voice.speak("مرحبا كيف يمكنني مساعدتك");
        break;

      // =================================
      // باقي الأوامر كلها تروح للـ Engine
      // =================================

      case OfflineAIBrain.openApp:
      case OfflineAIBrain.callContact:
      case OfflineAIBrain.playMusic:
      case OfflineAIBrain.youtubeSearch:
      case OfflineAIBrain.webSearch:
      case OfflineAIBrain.wifiControl:
      case OfflineAIBrain.bluetoothControl:
      case OfflineAIBrain.volumeControl:
      case OfflineAIBrain.cameraControl:
        await _engine.processCommand(_rebuildCommand(intent));
        break;

      // =================================
      // UNKNOWN
      // =================================

      case OfflineAIBrain.unknown:
        await _voice.speak("لم أفهم الأمر");
        break;

      // =================================
      // DEFAULT
      // =================================

      default:
        await _voice.speak("الأمر غير مدعوم");
        break;
    }
  }

  // =================================
  // REBUILD COMMAND FROM INTENT
  // (حل مؤقت عشان نستخدم الكود القديم)
  // =================================

  String _rebuildCommand(IntentModel intent) {
    if (intent.query != null) return intent.query!;
    if (intent.appName != null) return intent.appName!;
    if (intent.contactName != null) return intent.contactName!;

    return "";
  }

  // =================================
  // NORMALIZE TEXT
  // =================================

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(",", "")
        .replaceAll(".", "")
        .replaceAll("؟", "")
        .replaceAll("!", "")
        .replaceAll("  ", " ");
  }
}

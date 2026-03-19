import '../models/intent_model.dart';
import 'offline_ai_brain.dart';

class IntentParser {
  IntentParser({
    OfflineAIBrain? brain,
  }) : _brain = brain ?? OfflineAIBrain();

  final OfflineAIBrain _brain;

  /// Compatibility wrapper for old code paths.
  /// Prefer using OfflineAIBrain.analyze(...) directly in new code.
  Map<String, dynamic> parse(String text) {
    final intents = _brain.analyze(text);

    if (intents.isEmpty) {
      return _unknownResult();
    }

    return _toLegacyMap(intents.first);
  }

  Map<String, dynamic> _toLegacyMap(IntentModel intent) {
    return {
      'intent': _mapActionToLegacyIntent(intent.action),
      'entity': intent.contactName ?? intent.appName,
      'query': intent.query,
      'action': intent.action,
      'appName': intent.appName,
      'contactName': intent.contactName,
    };
  }

  Map<String, dynamic> _unknownResult() {
    return {
      'intent': 'unknown',
      'entity': null,
      'query': null,
      'action': OfflineAIBrain.unknown,
      'appName': null,
      'contactName': null,
    };
  }

  String _mapActionToLegacyIntent(String action) {
    switch (action) {
      case OfflineAIBrain.callContact:
        return 'call';

      case OfflineAIBrain.openApp:
        return 'open_app';

      case OfflineAIBrain.playMusic:
        return 'play_music';

      case OfflineAIBrain.webSearch:
      case OfflineAIBrain.youtubeSearch:
        return 'search';

      case OfflineAIBrain.acceptCall:
        return 'accept_call';

      case OfflineAIBrain.rejectCall:
        return 'reject_call';

      case OfflineAIBrain.wifiControl:
        return 'wifi_control';

      case OfflineAIBrain.bluetoothControl:
        return 'bluetooth_control';

      case OfflineAIBrain.volumeControl:
        return 'volume_control';

      case OfflineAIBrain.cameraControl:
        return 'camera_control';

      case OfflineAIBrain.greeting:
        return 'greeting';

      default:
        return 'unknown';
    }
  }
}

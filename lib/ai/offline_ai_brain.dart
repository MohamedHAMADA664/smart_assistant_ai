import '../models/intent_model.dart';

class OfflineAIBrain {
  // ===============================
  // INTENT TYPES
  // ===============================

  static const String openApp = "open_app";
  static const String callContact = "call_contact";
  static const String playMusic = "play_music";
  static const String youtubeSearch = "youtube_search";
  static const String webSearch = "web_search";
  static const String wifiControl = "wifi_control";
  static const String bluetoothControl = "bluetooth_control";
  static const String volumeControl = "volume_control";
  static const String cameraControl = "camera_control";
  static const String greeting = "greeting";

  // 🔥 جديد
  static const String acceptCall = "accept_call";
  static const String rejectCall = "reject_call";

  static const String unknown = "unknown";

  // ===============================
  // MAIN ANALYZE FUNCTION
  // ===============================

  List<IntentModel> analyze(String text) {
    String clean = _normalize(text);

    List<String> commands = _splitCommands(clean);

    List<IntentModel> intents = [];

    for (String command in commands) {
      String intent = detectIntent(command);

      intents.add(
        IntentModel(
          action: intent,
          appName: _extractAppName(command),
          contactName: _extractContactName(command),
          query: _extractQuery(command),
        ),
      );
    }

    return intents;
  }

  // ===============================
  // SPLIT MULTIPLE COMMANDS
  // ===============================

  List<String> _splitCommands(String text) {
    return text.split(RegExp(r"\s*(و|ثم|بعد كده|بعدها|and|then)\s*"));
  }

  // ===============================
  // DETECT INTENT
  // ===============================

  String detectIntent(String text) {
    // 🔥 CALL CONTROL (لازم يبقى فوق)
    if (_containsAny(text, ["رد", "اقبل", "ايوه", "نعم", "accept"])) {
      return acceptCall;
    }

    if (_containsAny(text, ["ارفض", "لا", "اقفل", "reject"])) {
      return rejectCall;
    }

    if (_containsAny(text, ["اهلا", "مرحبا", "ازيك", "hello", "hi"])) {
      return greeting;
    }

    if (_containsAny(text, ["اتصل", "كلم", "call", "dial"])) {
      return callContact;
    }

    if (_containsAny(text, ["يوتيوب", "youtube", "فيديو"])) {
      return youtubeSearch;
    }

    if (_containsAny(text, ["ابحث", "دور", "search", "google"])) {
      return webSearch;
    }

    if (_containsAny(text, ["اغاني", "موسيقى", "اسمع", "music", "song"])) {
      return playMusic;
    }

    if (_containsAny(text, ["واي فاي", "wifi"])) {
      return wifiControl;
    }

    if (_containsAny(text, ["بلوتوث", "bluetooth"])) {
      return bluetoothControl;
    }

    if (_containsAny(text, ["الصوت", "volume", "mute"])) {
      return volumeControl;
    }

    if (_containsAny(text, ["كاميرا", "صور", "camera", "photo"])) {
      return cameraControl;
    }

    if (_containsAny(text, ["افتح", "شغل", "ابدأ", "open", "launch"])) {
      return openApp;
    }

    return unknown;
  }

  // ===============================
  // EXTRACT APP NAME
  // ===============================

  String? _extractAppName(String text) {
    Map<String, String> apps = {
      "واتساب": "whatsapp",
      "whatsapp": "whatsapp",
      "يوتيوب": "youtube",
      "youtube": "youtube",
      "فيسبوك": "facebook",
      "facebook": "facebook",
      "انستجرام": "instagram",
      "instagram": "instagram",
      "تيك توك": "tiktok",
      "tiktok": "tiktok",
      "جوجل": "google",
      "google": "google",
      "كروم": "chrome",
      "chrome": "chrome"
    };

    for (var key in apps.keys) {
      if (text.contains(key)) {
        return apps[key];
      }
    }

    return null;
  }

  // ===============================
  // EXTRACT CONTACT NAME
  // ===============================

  String? _extractContactName(String text) {
    if (!_containsAny(text, ["اتصل", "كلم", "call", "dial"])) return null;

    List<String> words = text.split(" ");

    if (words.length < 2) return null;

    return words.last;
  }

  // ===============================
  // EXTRACT QUERY
  // ===============================

  String? _extractQuery(String text) {
    List<String> removeWords = [
      "ابحث",
      "عن",
      "search",
      "يوتيوب",
      "youtube",
      "شغل",
      "اغاني",
      "موسيقى",
      "video"
    ];

    String result = text;

    for (var word in removeWords) {
      result = result.replaceAll(word, "");
    }

    result = result.trim();

    if (result.isEmpty) return null;

    return result;
  }

  // ===============================
  // NORMALIZE
  // ===============================

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll("يا", "")
        .replaceAll("لو سمحت", "")
        .replaceAll("ممكن", "")
        .replaceAll("من فضلك", "")
        .replaceAll("please", "")
        .replaceAll(",", "")
        .replaceAll(".", "")
        .replaceAll("؟", "")
        .replaceAll("!", "")
        .trim();
  }

  // ===============================
  // KEYWORD MATCH
  // ===============================

  bool _containsAny(String text, List<String> words) {
    for (var word in words) {
      if (text.contains(word)) return true;
    }
    return false;
  }
}

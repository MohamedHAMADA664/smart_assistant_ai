class IntentParser {
  Map<String, dynamic> parse(String text) {
    String input = text.toLowerCase();

    Map<String, dynamic> result = {
      "intent": "unknown",
      "entity": null,
      "query": null
    };

    // CALL

    if (_containsAny(input, ["اتصل", "كلم", "call"])) {
      result["intent"] = "call";

      result["entity"] = _extractName(input);

      return result;
    }

    // OPEN APP

    if (_containsAny(input, ["افتح", "open", "launch"])) {
      result["intent"] = "open_app";

      result["entity"] = _extractApp(input);

      return result;
    }

    // MUSIC

    if (_containsAny(input, ["اغاني", "music", "موسيقى"])) {
      result["intent"] = "play_music";

      result["query"] = input;

      return result;
    }

    // SEARCH

    if (_containsAny(input, ["ابحث", "search"])) {
      result["intent"] = "search";

      result["query"] = input;

      return result;
    }

    return result;
  }

  bool _containsAny(String text, List<String> words) {
    for (var w in words) {
      if (text.contains(w)) {
        return true;
      }
    }

    return false;
  }

  String? _extractName(String text) {
    List<String> words = text.split(" ");

    if (words.length > 1) {
      return words.last;
    }

    return null;
  }

  String? _extractApp(String text) {
    Map<String, String> apps = {
      "واتساب": "whatsapp",
      "youtube": "youtube",
      "يوتيوب": "youtube",
      "فيس": "facebook",
      "facebook": "facebook",
      "انستجرام": "instagram",
      "instagram": "instagram"
    };

    for (var key in apps.keys) {
      if (text.contains(key)) {
        return apps[key];
      }
    }

    return null;
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String wakeWordKey = "wake_word";

  static Future<void> saveWakeWord(String word) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(wakeWordKey, word);
  }

  static Future<String> getWakeWord() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(wakeWordKey) ?? "يا مساعدي";
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class AssistantSettings {
  static const String wakeWordKey = 'assistant_wake_word';

  // حفظ اسم المساعد
  static Future<void> setWakeWord(String name) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(wakeWordKey, name.toLowerCase());
  }

  // قراءة اسم المساعد
  static Future<String> getWakeWord() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(wakeWordKey) ?? 'مساعدي';
  }
}

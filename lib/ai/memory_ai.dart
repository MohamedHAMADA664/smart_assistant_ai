import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryAI {
  // ===============================
  // INTERNAL MEMORY STORAGE
  // ===============================

  final Map<String, String> _memory = {};
  final List<String> _history = []; // 🔥 جديد (تتبع الأوامر)

  static const String _storageKey = "assistant_memory";
  static const String _historyKey = "assistant_history"; // 🔥 جديد

  bool _initialized = false;

  // ===============================
  // INITIALIZE MEMORY
  // ===============================

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();

    // 🔹 Load memory
    String? savedMemory = prefs.getString(_storageKey);

    if (savedMemory != null) {
      Map<String, dynamic> decoded = jsonDecode(savedMemory);

      decoded.forEach((key, value) {
        _memory[key] = value.toString();
      });
    }

    // 🔹 Load history 🔥
    List<String>? savedHistory = prefs.getStringList(_historyKey);

    if (savedHistory != null) {
      _history.addAll(savedHistory);
    }

    _initialized = true;
  }

  // ===============================
  // 🔥 SAVE QUICK COMMAND (حل المشكلة)
  // ===============================

  Future<void> save(String text) async {
    text = text.trim();

    if (text.isEmpty) return;

    _history.add(text);

    // limit history size 🔥
    if (_history.length > 50) {
      _history.removeAt(0);
    }

    await _saveHistory();
  }

  // ===============================
  // SAVE MEMORY (KEY-VALUE)
  // ===============================

  Future<void> remember(String key, String value) async {
    key = key.toLowerCase().trim();
    value = value.trim();

    if (key.isEmpty || value.isEmpty) return;

    _memory[key] = value;

    await _saveToStorage();
  }

  // ===============================
  // GET MEMORY
  // ===============================

  String? recall(String key) {
    key = key.toLowerCase().trim();

    return _memory[key];
  }

  // ===============================
  // CHECK IF MEMORY EXISTS
  // ===============================

  bool hasMemory(String key) {
    key = key.toLowerCase().trim();

    return _memory.containsKey(key);
  }

  // ===============================
  // DELETE MEMORY
  // ===============================

  Future<void> forget(String key) async {
    key = key.toLowerCase().trim();

    _memory.remove(key);

    await _saveToStorage();
  }

  // ===============================
  // CLEAR ALL MEMORY
  // ===============================

  Future<void> clearMemory() async {
    _memory.clear();
    _history.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_historyKey);
  }

  // ===============================
  // GET ALL MEMORY
  // ===============================

  Map<String, String> getAllMemory() {
    return Map.from(_memory);
  }

  // ===============================
  // 🔥 GET HISTORY
  // ===============================

  List<String> getHistory() {
    return List.from(_history);
  }

  // ===============================
  // SAVE MEMORY TO DEVICE
  // ===============================

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    String encoded = jsonEncode(_memory);

    await prefs.setString(_storageKey, encoded);
  }

  // ===============================
  // 🔥 SAVE HISTORY
  // ===============================

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_historyKey, _history);
  }
}

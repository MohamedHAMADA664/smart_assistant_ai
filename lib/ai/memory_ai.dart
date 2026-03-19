import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MemoryAI {
  static const String _storageKey = 'assistant_memory';
  static const String _historyKey = 'assistant_history';
  static const int _maxHistoryItems = 50;

  final Map<String, String> _memory = <String, String>{};
  final List<String> _history = <String>[];

  SharedPreferences? _prefs;
  bool _initialized = false;

  // ===============================
  // INITIALIZE
  // ===============================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();

    await _loadMemory();
    await _loadHistory();

    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ===============================
  // SAVE QUICK COMMAND / HISTORY
  // ===============================

  Future<void> save(String text) async {
    await _ensureInitialized();

    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return;
    }

    _history.add(normalizedText);

    if (_history.length > _maxHistoryItems) {
      _history.removeRange(0, _history.length - _maxHistoryItems);
    }

    await _saveHistory();
  }

  // ===============================
  // SAVE MEMORY (KEY-VALUE)
  // ===============================

  Future<void> remember(String key, String value) async {
    await _ensureInitialized();

    final normalizedKey = _normalizeKey(key);
    final normalizedValue = value.trim();

    if (normalizedKey.isEmpty || normalizedValue.isEmpty) {
      return;
    }

    _memory[normalizedKey] = normalizedValue;
    await _saveMemory();
  }

  // ===============================
  // GET MEMORY
  // ===============================

  Future<String?> recall(String key) async {
    await _ensureInitialized();

    final normalizedKey = _normalizeKey(key);
    if (normalizedKey.isEmpty) {
      return null;
    }

    return _memory[normalizedKey];
  }

  // ===============================
  // CHECK IF MEMORY EXISTS
  // ===============================

  Future<bool> hasMemory(String key) async {
    await _ensureInitialized();

    final normalizedKey = _normalizeKey(key);
    if (normalizedKey.isEmpty) {
      return false;
    }

    return _memory.containsKey(normalizedKey);
  }

  // ===============================
  // DELETE MEMORY
  // ===============================

  Future<void> forget(String key) async {
    await _ensureInitialized();

    final normalizedKey = _normalizeKey(key);
    if (normalizedKey.isEmpty) {
      return;
    }

    _memory.remove(normalizedKey);
    await _saveMemory();
  }

  // ===============================
  // CLEAR ALL MEMORY
  // ===============================

  Future<void> clearMemory() async {
    await _ensureInitialized();

    _memory.clear();
    _history.clear();

    await _prefs!.remove(_storageKey);
    await _prefs!.remove(_historyKey);
  }

  // ===============================
  // GET ALL MEMORY
  // ===============================

  Future<Map<String, String>> getAllMemory() async {
    await _ensureInitialized();
    return Map<String, String>.from(_memory);
  }

  // ===============================
  // GET HISTORY
  // ===============================

  Future<List<String>> getHistory() async {
    await _ensureInitialized();
    return List<String>.from(_history);
  }

  // ===============================
  // INTERNAL LOADERS
  // ===============================

  Future<void> _loadMemory() async {
    final savedMemory = _prefs?.getString(_storageKey);
    if (savedMemory == null || savedMemory.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(savedMemory);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    _memory.clear();
    decoded.forEach((key, value) {
      final normalizedKey = _normalizeKey(key);
      final normalizedValue = value.toString().trim();

      if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
        _memory[normalizedKey] = normalizedValue;
      }
    });
  }

  Future<void> _loadHistory() async {
    final savedHistory = _prefs?.getStringList(_historyKey);
    if (savedHistory == null || savedHistory.isEmpty) {
      return;
    }

    _history
      ..clear()
      ..addAll(
        savedHistory
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );

    if (_history.length > _maxHistoryItems) {
      _history.removeRange(0, _history.length - _maxHistoryItems);
    }
  }

  // ===============================
  // INTERNAL SAVERS
  // ===============================

  Future<void> _saveMemory() async {
    await _prefs!.setString(_storageKey, jsonEncode(_memory));
  }

  Future<void> _saveHistory() async {
    await _prefs!.setStringList(_historyKey, List<String>.from(_history));
  }

  // ===============================
  // HELPERS
  // ===============================

  String _normalizeKey(String key) {
    return key.toLowerCase().trim();
  }
}

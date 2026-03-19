import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'voice_listener_service.dart';

class BackgroundAssistantService {
  // ===============================
  // START SERVICE
  // ===============================

  static Future<void> startService() async {
    final isRunning = await FlutterForegroundTask.isRunningService;

    if (isRunning) {
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'المساعد الذكي يعمل',
      notificationText: 'المساعد يستمع للأوامر الصوتية',
      callback: startCallback,
    );
  }

  // ===============================
  // STOP SERVICE
  // ===============================

  static Future<void> stopService() async {
    final isRunning = await FlutterForegroundTask.isRunningService;

    if (!isRunning) {
      return;
    }

    await FlutterForegroundTask.stopService();
  }

  // ===============================
  // GET STATUS
  // ===============================

  static Future<bool> isServiceRunning() async {
    return FlutterForegroundTask.isRunningService;
  }
}

// =====================================
// FOREGROUND CALLBACK
// =====================================

void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    AssistantTaskHandler(),
  );
}

// =====================================
// TASK HANDLER
// =====================================

class AssistantTaskHandler extends TaskHandler {
  final VoiceListenerService _voiceListener = VoiceListenerService();

  bool _started = false;

  // ===============================
  // SERVICE START
  // ===============================

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    if (_started) {
      return;
    }

    try {
      await _ensureVoiceListenerStarted();
      _started = true;
    } catch (_) {
      _started = false;
    }
  }

  // ===============================
  // REPEAT EVENT
  // ===============================

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    try {
      if (!_started) {
        await _ensureVoiceListenerStarted();
        _started = true;
        return;
      }

      if (!_voiceListener.isListening) {
        await _voiceListener.startListening();
      }
    } catch (_) {
      // Ignore periodic recovery errors silently for now.
    }
  }

  // ===============================
  // SERVICE STOP
  // ===============================

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    try {
      await _voiceListener.dispose();
    } catch (_) {
      // Ignore shutdown errors silently for now.
    } finally {
      _started = false;
    }
  }

  // ===============================
  // NOTIFICATION BUTTON
  // ===============================

  @override
  void onNotificationButtonPressed(String id) {
    // Reserved for future notification actions.
  }

  // ===============================
  // NOTIFICATION CLICK
  // ===============================

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  // ===============================
  // INTERNAL HELPERS
  // ===============================

  Future<void> _ensureVoiceListenerStarted() async {
    await _voiceListener.initialize();

    if (!_voiceListener.isListening) {
      await _voiceListener.startListening();
    }
  }
}

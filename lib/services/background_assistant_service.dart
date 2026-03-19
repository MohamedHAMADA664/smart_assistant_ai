import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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
      notificationText: 'المساعد جاهز ويعمل في الخلفية',
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
  bool _started = false;

  // ===============================
  // SERVICE START
  // ===============================

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    if (_started) {
      return;
    }

    _started = true;

    FlutterForegroundTask.updateService(
      notificationTitle: 'المساعد الذكي يعمل',
      notificationText: 'الخدمة الخلفية نشطة، افتح التطبيق لاستخدام الاستماع',
    );
  }

  // ===============================
  // REPEAT EVENT
  // ===============================

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    if (!_started) {
      _started = true;
    }

    FlutterForegroundTask.updateService(
      notificationTitle: 'المساعد الذكي يعمل',
      notificationText: 'الخدمة الخلفية نشطة، افتح التطبيق لاستخدام الاستماع',
    );
  }

  // ===============================
  // SERVICE STOP
  // ===============================

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _started = false;
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
}

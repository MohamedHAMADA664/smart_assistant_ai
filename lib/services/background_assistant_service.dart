import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'voice_listener_service.dart';

// =====================================
// BACKGROUND SERVICE CONTROLLER
// =====================================

class BackgroundAssistantService {
  static Future<void> startService() async {
    await FlutterForegroundTask.startService(
      notificationTitle: "المساعد الذكي يعمل",
      notificationText: "المساعد يستمع للأوامر الصوتية",
      callback: startCallback,
    );
  }

  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
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

  // ===============================
  // SERVICE START
  // ===============================

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    await _voiceListener.initialize();

    await _voiceListener.startListening();
  }

  // ===============================
  // REPEAT EVENT (REQUIRED)
  // ===============================

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // يمكن وضع مهام دورية هنا لاحقاً
    // مثل فحص حالة الميكروفون أو إعادة تشغيل الاستماع
  }

  // ===============================
  // SERVICE STOP
  // ===============================

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await _voiceListener.stopListening();
  }

  // ===============================
  // NOTIFICATION BUTTON
  // ===============================

  @override
  void onNotificationButtonPressed(String id) {
    // يمكن إضافة أزرار للتحكم لاحقاً
  }

  // ===============================
  // NOTIFICATION CLICK
  // ===============================

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/");
  }
}

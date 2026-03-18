import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'background_assistant_service.dart';

// =====================================
// BOOT RECEIVER SERVICE
// =====================================

class BootReceiver {
  // =====================================
  // START ASSISTANT AFTER BOOT
  // =====================================

  static Future<void> startAssistantAfterBoot() async {
    bool isRunning = await FlutterForegroundTask.isRunningService;

    if (!isRunning) {
      await BackgroundAssistantService.startService();
    }
  }
}

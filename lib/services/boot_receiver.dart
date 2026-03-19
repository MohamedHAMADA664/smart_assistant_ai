import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'background_assistant_service.dart';

class BootReceiverService {
  // ===============================
  // START ASSISTANT AFTER BOOT
  // ===============================

  Future<bool> startAssistantAfterBoot() async {
    try {
      final isRunning = await FlutterForegroundTask.isRunningService;

      if (isRunning) {
        return true;
      }

      await BackgroundAssistantService.startService();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===============================
  // ENSURE SERVICE RUNNING
  // ===============================

  Future<bool> ensureAssistantRunning() async {
    return startAssistantAfterBoot();
  }
}

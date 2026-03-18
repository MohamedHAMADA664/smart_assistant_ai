import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'screens/home_screen.dart';
import 'services/call_handler_service.dart'; // 🔥 جديد

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد خدمة الخلفية
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'assistant_service',
      channelName: 'Smart Assistant Service',
      channelDescription: 'Background voice assistant service',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      isOnceEvent: false,
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // 🔥 تشغيل نظام استقبال المكالمات
  CallHandlerService().init();

  runApp(const SmartAssistant());
}

class SmartAssistant extends StatelessWidget {
  const SmartAssistant({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Smart Assistant",
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

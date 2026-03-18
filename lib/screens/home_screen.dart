import 'package:flutter/material.dart';

import '../widgets/ai_orb.dart';
import '../widgets/cosmic_background.dart';
import '../services/background_assistant_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool assistantRunning = false;

  // =========================
  // START ASSISTANT
  // =========================

  void startAssistant() async {
    await BackgroundAssistantService.startService();

    setState(() {
      assistantRunning = true;
    });
  }

  // =========================
  // STOP ASSISTANT
  // =========================

  void stopAssistant() async {
    await BackgroundAssistantService.stopService();

    setState(() {
      assistantRunning = false;
    });
  }

  Widget buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xff111111),
        child: ListView(
          children: const [
            DrawerHeader(
              child: Text(
                "المساعد الذكي",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text(
                "الإعدادات",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.language, color: Colors.white),
              title: Text(
                "اللغة",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.white),
              title: Text(
                "حول التطبيق",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "كيف يمكنني مساعدتك؟",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),

              const SizedBox(height: 40),

              const Center(
                child: AIOrb(),
              ),

              const SizedBox(height: 30),

              // =========================
              // ASSISTANT CONTROL BUTTON
              // =========================

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: assistantRunning ? Colors.red : Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
                icon: Icon(
                  assistantRunning ? Icons.stop : Icons.mic,
                ),
                label: Text(
                  assistantRunning ? "إيقاف المساعد" : "تشغيل المساعد",
                ),
                onPressed: () {
                  if (assistantRunning) {
                    stopAssistant();
                  } else {
                    startAssistant();
                  }
                },
              ),

              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildActionIcon(Icons.call, "اتصال"),
                  buildActionIcon(Icons.message, "رسائل"),
                  buildActionIcon(Icons.location_on, "أماكن"),
                  buildActionIcon(Icons.music_note, "موسيقى"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

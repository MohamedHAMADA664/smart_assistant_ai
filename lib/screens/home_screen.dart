import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../screens/settings_screen.dart';
import '../services/app_control_service.dart';
import '../services/assistant_profile_service.dart';
import '../services/background_assistant_service.dart';
import '../services/voice_listener_service.dart';
import '../widgets/ai_orb.dart';
import '../widgets/cosmic_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AssistantProfileService _assistantProfileService =
      AssistantProfileService();
  final AppControlService _appControlService = AppControlService();
  final VoiceListenerService _voiceListenerService = VoiceListenerService();

  bool _assistantRunning = false;
  bool _isBusy = false;
  bool _isProfileLoading = true;
  bool _isInitializingVoice = false;
  bool _isVoiceListening = false;

  String _assistantName = 'مساعدي';
  String _wakeWord = 'يا مساعدي';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceListenerService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_assistantRunning) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _restoreVoiceListeningIfNeeded();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseVoiceListeningForBackground();
    }
  }

  // =========================
  // INITIALIZE SCREEN
  // =========================

  Future<void> _initializeScreen() async {
    await Future.wait([
      _loadAssistantStatus(),
      _loadAssistantProfile(),
    ]);

    await _restoreVoiceListeningIfNeeded();
  }

  // =========================
  // LOAD PROFILE
  // =========================

  Future<void> _loadAssistantProfile() async {
    try {
      final profile = await _assistantProfileService.loadProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _assistantName = profile.assistantName;
        _wakeWord = profile.wakeWord;
        _isProfileLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _assistantName = 'مساعدي';
        _wakeWord = 'يا مساعدي';
        _isProfileLoading = false;
      });
    }
  }

  // =========================
  // LOAD REAL SERVICE STATUS
  // =========================

  Future<void> _loadAssistantStatus() async {
    try {
      final isRunning = await FlutterForegroundTask.isRunningService;

      if (!mounted) {
        return;
      }

      setState(() {
        _assistantRunning = isRunning;
        _isVoiceListening = _voiceListenerService.isListening;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _assistantRunning = false;
        _isVoiceListening = false;
      });
    }
  }

  // =========================
  // RESTORE VOICE LISTENING
  // =========================

  Future<void> _restoreVoiceListeningIfNeeded() async {
    if (!_assistantRunning) {
      return;
    }

    if (_isInitializingVoice) {
      return;
    }

    _isInitializingVoice = true;

    try {
      await _voiceListenerService.initialize();

      if (!_voiceListenerService.isListening) {
        await _voiceListenerService.startListening();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isVoiceListening = _voiceListenerService.isListening;
      });
    } catch (_) {
      if (mounted) {
        _showSnackBar('تعذر تهيئة الاستماع الصوتي');
        setState(() {
          _isVoiceListening = false;
        });
      }
    } finally {
      _isInitializingVoice = false;
    }
  }

  // =========================
  // PAUSE VOICE LISTENING
  // =========================

  Future<void> _pauseVoiceListeningForBackground() async {
    try {
      await _voiceListenerService.stopListening();

      if (!mounted) {
        return;
      }

      setState(() {
        _isVoiceListening = false;
      });
    } catch (_) {
      // تجاهل أخطاء الإيقاف في الخلفية
    }
  }

  // =========================
  // OPEN SETTINGS
  // =========================

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );

    await _loadAssistantProfile();
  }

  // =========================
  // START ASSISTANT
  // =========================

  Future<void> _startAssistant() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      await BackgroundAssistantService.startService();
      await _voiceListenerService.initialize();
      await _voiceListenerService.startListening();

      if (!mounted) {
        return;
      }

      setState(() {
        _assistantRunning = true;
        _isVoiceListening = _voiceListenerService.isListening;
      });

      _showSnackBar('تم تشغيل المساعد وبدء الاستماع داخل التطبيق');
    } catch (_) {
      _showSnackBar('تعذر تشغيل المساعد');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  // =========================
  // STOP ASSISTANT
  // =========================

  Future<void> _stopAssistant() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      await _voiceListenerService.stopListening();
      await BackgroundAssistantService.stopService();

      if (!mounted) {
        return;
      }

      setState(() {
        _assistantRunning = false;
        _isVoiceListening = false;
      });

      _showSnackBar('تم إيقاف المساعد');
    } catch (_) {
      _showSnackBar('تعذر إيقاف المساعد');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  // =========================
  // QUICK ACTIONS
  // =========================

  Future<void> _openPhoneApp() async {
    final opened = await _appControlService.openAppByName('الهاتف') ||
        await _appControlService.openAppByName('phone') ||
        await _appControlService.openAppByName('dialer');

    if (!opened) {
      _showSnackBar('تعذر فتح تطبيق الهاتف');
    }
  }

  Future<void> _openMessagesApp() async {
    final opened = await _appControlService.openAppByName('الرسائل') ||
        await _appControlService.openAppByName('messages') ||
        await _appControlService.openAppByName('sms');

    if (!opened) {
      _showSnackBar('تعذر فتح تطبيق الرسائل');
    }
  }

  Future<void> _openMapsApp() async {
    final opened = await _appControlService.openAppByName('خرائط') ||
        await _appControlService.openAppByName('maps') ||
        await _appControlService.openAppByName('google maps');

    if (!opened) {
      _showSnackBar('تعذر فتح الخرائط');
    }
  }

  Future<void> _openMusicApp() async {
    final opened = await _appControlService.openAppByName('يوتيوب ميوزيك') ||
        await _appControlService.openAppByName('youtube music') ||
        await _appControlService.openAppByName('music') ||
        await _appControlService.openAppByName('spotify');

    if (!opened) {
      _showSnackBar('تعذر فتح تطبيق الموسيقى');
    }
  }

  // =========================
  // SNACKBAR
  // =========================

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================
  // ACTION ITEM
  // =========================

  Widget _buildActionIcon(
    IconData icon,
    String label,
    Future<void> Function() onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
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
          ),
        ],
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final buttonColor = _assistantRunning ? Colors.red : Colors.green;
    final buttonIcon = _assistantRunning ? Icons.stop : Icons.mic;
    final buttonText = _assistantRunning ? 'إيقاف المساعد' : 'تشغيل المساعد';

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xff111111),
        child: ListView(
          children: [
            DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  _isProfileLoading ? 'المساعد الذكي' : _assistantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'الإعدادات',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _openSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over, color: Colors.white),
              title: const Text(
                'كلمة النداء',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _wakeWord,
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.info, color: Colors.white),
              title: Text(
                'حول التطبيق',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        return IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        );
                      },
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _assistantRunning ? 'الحالة: يعمل' : 'الحالة: متوقف',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isVoiceListening
                                ? 'الاستماع: نشط'
                                : 'الاستماع: غير نشط',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _isProfileLoading
                      ? 'كيف يمكنني مساعدتك؟'
                      : 'مرحبًا، أنا $_assistantName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'نادني بقول: $_wakeWord',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: AIOrb(),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    disabledBackgroundColor: buttonColor.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                  ),
                  icon: _isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(buttonIcon),
                  label: Text(
                    _isBusy ? 'جارٍ التنفيذ...' : buttonText,
                  ),
                  onPressed: _isBusy
                      ? null
                      : () {
                          if (_assistantRunning) {
                            _stopAssistant();
                          } else {
                            _startAssistant();
                          }
                        },
                ),
                const SizedBox(height: 14),
                Text(
                  _assistantRunning
                      ? 'المساعد يعمل، والاستماع يكون داخل التطبيق أثناء فتحه'
                      : 'اضغط لتشغيل المساعد وبدء الاستماع',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionIcon(Icons.call, 'اتصال', _openPhoneApp),
                    _buildActionIcon(Icons.message, 'رسائل', _openMessagesApp),
                    _buildActionIcon(Icons.location_on, 'أماكن', _openMapsApp),
                    _buildActionIcon(Icons.music_note, 'موسيقى', _openMusicApp),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

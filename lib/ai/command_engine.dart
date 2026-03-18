import '../services/voice_response_service.dart';
import '../services/app_control_service.dart';
import '../services/music_service.dart';
import '../services/system_control_service.dart';
import '../services/camera_service.dart';
import '../services/call_control_service.dart';

import 'memory_ai.dart';
import 'offline_ai_brain.dart';
import '../models/intent_model.dart';

class CommandEngine {
  final AppControlService _appControl = AppControlService();
  final MusicService _musicService = MusicService();
  final SystemControlService _systemService = SystemControlService();
  final CameraService _cameraService = CameraService();
  final CallControlService _callService = CallControlService();

  final VoiceResponseService _voice = VoiceResponseService();
  final MemoryAI _memory = MemoryAI();
  final OfflineAIBrain _brain = OfflineAIBrain();

  // ================================
  // MAIN
  // ================================

  Future<void> processCommand(String text) async {
    try {
      // 🔥 تخزين في الذاكرة
      _memory.save(text);

      List<IntentModel> intents = _brain.analyze(text);

      if (intents.isEmpty) {
        await _voice.speak("لم افهم الامر");
        return;
      }

      for (var intent in intents) {
        await _executeIntent(intent);
      }
    } catch (e) {
      await _voice.speak("حدث خطأ");
    }
  }

  // ================================
  // EXECUTE INTENT (🔥 الجديد)
  // ================================

  Future<void> _executeIntent(IntentModel intent) async {
    try {
      switch (intent.action) {
        // =========================
        // CALL CONTROL 🔥
        // =========================

        case OfflineAIBrain.acceptCall:
          await _voice.speak("جاري الرد");
          await _callService.acceptCall();
          break;

        case OfflineAIBrain.rejectCall:
          await _voice.speak("تم رفض المكالمة");
          await _callService.rejectCall();
          break;

        // =========================
        // OPEN APP
        // =========================

        case OfflineAIBrain.openApp:
          await _voice.speak("حسنا");
          if (intent.appName != null && intent.appName!.isNotEmpty) {
            await _appControl.openAppByName(intent.appName!);
          } else {
            await _voice.speak("حدد اسم التطبيق");
          }
          break;

        // =========================
        // MUSIC
        // =========================

        case OfflineAIBrain.playMusic:
          await _voice.speak("جاري تشغيل الموسيقى");
          await _musicService.playMusic(intent.query ?? "music");
          break;

        // =========================
        // YOUTUBE
        // =========================

        case OfflineAIBrain.youtubeSearch:
          await _voice.speak("جاري البحث في يوتيوب");

          if (intent.query != null && intent.query!.isNotEmpty) {
            await _musicService.playYoutube(intent.query!);
          } else {
            await _voice.speak("ماذا تريد البحث عنه");
          }
          break;

        // =========================
        // WEB SEARCH
        // =========================

        case OfflineAIBrain.webSearch:
          await _voice.speak("جاري البحث");

          if (intent.query != null && intent.query!.isNotEmpty) {
            await _systemService.webSearch(intent.query!);
          } else {
            await _voice.speak("ما الذي تريد البحث عنه");
          }
          break;

        // =========================
        // WIFI
        // =========================

        case OfflineAIBrain.wifiControl:
          await _voice.speak("فتح إعدادات الواي فاي");
          await _systemService.openWifiSettings();
          break;

        // =========================
        // BLUETOOTH
        // =========================

        case OfflineAIBrain.bluetoothControl:
          await _voice.speak("فتح البلوتوث");
          await _systemService.openBluetoothSettings();
          break;

        // =========================
        // VOLUME
        // =========================

        case OfflineAIBrain.volumeControl:
          await _systemService.volumeUp();
          break;

        // =========================
        // CAMERA
        // =========================

        case OfflineAIBrain.cameraControl:
          await _voice.speak("فتح الكاميرا");
          await _cameraService.openCamera();
          break;

        // =========================
        // GREETING
        // =========================

        case OfflineAIBrain.greeting:
          await _voice.speak("اهلا بيك");
          break;

        // =========================
        // UNKNOWN
        // =========================

        default:
          await _voice.speak("لم افهم الامر");
          break;
      }
    } catch (e) {
      await _voice.speak("حدث خطأ أثناء التنفيذ");
    }
  }
}

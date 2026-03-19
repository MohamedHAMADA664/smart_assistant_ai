import '../models/intent_model.dart';
import '../services/app_control_service.dart';
import '../services/call_control_service.dart';
import '../services/camera_service.dart';
import '../services/music_service.dart';
import '../services/system_control_service.dart';
import '../services/voice_response_service.dart';
import 'memory_ai.dart';
import 'offline_ai_brain.dart';

class CommandEngine {
  CommandEngine({
    AppControlService? appControlService,
    MusicService? musicService,
    SystemControlService? systemControlService,
    CameraService? cameraService,
    CallControlService? callControlService,
    VoiceResponseService? voiceResponseService,
    MemoryAI? memoryAI,
    OfflineAIBrain? brain,
  })  : _appControl = appControlService ?? AppControlService(),
        _musicService = musicService ?? MusicService(),
        _systemService = systemControlService ?? SystemControlService(),
        _cameraService = cameraService ?? CameraService(),
        _callService = callControlService ?? CallControlService(),
        _voice = voiceResponseService ?? VoiceResponseService(),
        _memory = memoryAI ?? MemoryAI(),
        _brain = brain ?? OfflineAIBrain();

  final AppControlService _appControl;
  final MusicService _musicService;
  final SystemControlService _systemService;
  final CameraService _cameraService;
  final CallControlService _callService;
  final VoiceResponseService _voice;
  final MemoryAI _memory;
  final OfflineAIBrain _brain;

  bool _isInitialized = false;

  // ================================
  // INITIALIZE
  // ================================

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _memory.initialize();
    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ================================
  // BACKWARD COMPATIBILITY
  // ================================

  Future<void> processCommand(String text) async {
    await _ensureInitialized();

    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      await _voice.speak('لم أفهم الأمر');
      return;
    }

    try {
      await _memory.save(normalizedText);

      final intents = _brain.analyze(normalizedText);

      if (intents.isEmpty) {
        await _voice.speak('لم أفهم الأمر');
        return;
      }

      for (final intent in intents) {
        await executeIntent(intent);
      }
    } catch (_) {
      await _voice.speak('حدث خطأ أثناء تنفيذ الأمر');
    }
  }

  // ================================
  // NEW OFFICIAL EXECUTION PATH
  // ================================

  Future<void> executeIntent(IntentModel intent) async {
    await _ensureInitialized();

    try {
      await _rememberIntent(intent);

      switch (intent.action) {
        case OfflineAIBrain.acceptCall:
          await _voice.speak('جاري الرد');
          await _callService.acceptCall();
          return;

        case OfflineAIBrain.rejectCall:
          await _voice.speak('تم رفض المكالمة');
          await _callService.rejectCall();
          return;

        case OfflineAIBrain.openApp:
          await _handleOpenApp(intent);
          return;

        case OfflineAIBrain.callContact:
          await _handleCallContact(intent);
          return;

        case OfflineAIBrain.playMusic:
          await _handlePlayMusic(intent);
          return;

        case OfflineAIBrain.youtubeSearch:
          await _handleYoutubeSearch(intent);
          return;

        case OfflineAIBrain.webSearch:
          await _handleWebSearch(intent);
          return;

        case OfflineAIBrain.wifiControl:
          await _voice.speak('فتح إعدادات الواي فاي');
          await _systemService.openWifiSettings();
          return;

        case OfflineAIBrain.bluetoothControl:
          await _voice.speak('فتح إعدادات البلوتوث');
          await _systemService.openBluetoothSettings();
          return;

        case OfflineAIBrain.volumeControl:
          await _systemService.volumeUp();
          return;

        case OfflineAIBrain.cameraControl:
          await _voice.speak('فتح الكاميرا');
          await _cameraService.openCamera();
          return;

        case OfflineAIBrain.greeting:
          await _voice.speak('أهلا بيك');
          return;

        case OfflineAIBrain.unknown:
          await _voice.speak('لم أفهم الأمر');
          return;

        default:
          await _voice.speak('الأمر غير مدعوم حاليًا');
          return;
      }
    } catch (_) {
      await _voice.speak('حدث خطأ أثناء التنفيذ');
    }
  }

  // ================================
  // HANDLERS
  // ================================

  Future<void> _handleOpenApp(IntentModel intent) async {
    final appName = intent.appName?.trim();

    if (appName == null || appName.isEmpty) {
      await _voice.speak('حدد اسم التطبيق');
      return;
    }

    await _voice.speak('حسنًا');
    await _appControl.openAppByName(appName);
  }

  Future<void> _handleCallContact(IntentModel intent) async {
    final contactName = intent.contactName?.trim();

    if (contactName == null || contactName.isEmpty) {
      await _voice.speak('حدد اسم الشخص الذي تريد الاتصال به');
      return;
    }

    await _voice.speak(
      'أمر الاتصال بجهة الاتصال جاهز، وسنربطه بخدمة جهات الاتصال في الخطوة القادمة',
    );
  }

  Future<void> _handlePlayMusic(IntentModel intent) async {
    final query = intent.query?.trim();

    await _voice.speak('جاري تشغيل الموسيقى');
    await _musicService.playMusic(
      (query == null || query.isEmpty) ? 'music' : query,
    );
  }

  Future<void> _handleYoutubeSearch(IntentModel intent) async {
    final query = intent.query?.trim();

    if (query == null || query.isEmpty) {
      await _voice.speak('ماذا تريد البحث عنه');
      return;
    }

    await _voice.speak('جاري البحث في يوتيوب');
    await _musicService.playYoutube(query);
  }

  Future<void> _handleWebSearch(IntentModel intent) async {
    final query = intent.query?.trim();

    if (query == null || query.isEmpty) {
      await _voice.speak('ما الذي تريد البحث عنه');
      return;
    }

    await _voice.speak('جاري البحث');
    await _systemService.webSearch(query);
  }

  Future<void> _rememberIntent(IntentModel intent) async {
    final memoryText = [
      intent.action,
      intent.appName,
      intent.contactName,
      intent.query,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' | ');

    if (memoryText.isNotEmpty) {
      await _memory.save(memoryText);
    }
  }
}

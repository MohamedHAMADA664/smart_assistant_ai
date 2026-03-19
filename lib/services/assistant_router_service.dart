import 'app_task_planner_service.dart';
import 'online_ai_service.dart';
import 'openai_gateway.dart';

class AssistantRouterService {
  AssistantRouterService({
    AppTaskPlannerService? appTaskPlannerService,
    OnlineAiService? onlineAiService,
  })  : _appTaskPlannerService =
            appTaskPlannerService ?? AppTaskPlannerService(),
        _onlineAiService = onlineAiService ??
            OnlineAiService(
              gateway: OpenAiGateway(),
            );

  final AppTaskPlannerService _appTaskPlannerService;
  final OnlineAiService _onlineAiService;

  // ================================
  // ROUTE REQUEST
  // ================================

  Future<AssistantRouteResult> route(String rawText) async {
    final normalizedText = _normalize(rawText);

    if (normalizedText.isEmpty) {
      return const AssistantRouteResult(
        routeType: AssistantRouteType.invalid,
        message: 'النص المدخل فارغ',
      );
    }

    // ================================
    // 1) SMALL TALK FIRST
    // ================================

    if (_looksLikeSmallTalk(normalizedText)) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.smallTalk,
        message: 'تم توجيه الطلب إلى الردود المحلية البسيطة',
        originalText: rawText,
      );
    }

    // ================================
    // 2) LOCAL APP / DEVICE PLANNING FIRST
    // ================================

    final appTaskPlan = await _appTaskPlannerService.planFromText(rawText);

    if (appTaskPlan.isReady && appTaskPlan.task != null) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.appTask,
        message: 'تم توجيه الطلب إلى مهام التطبيقات',
        originalText: rawText,
        appTaskPlanResult: appTaskPlan,
      );
    }

    // ================================
    // 3) DIRECT DEVICE / APP ACTIONS MUST STAY LOCAL
    // ================================

    if (_looksLikeDirectDeviceAction(normalizedText)) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.appTask,
        message: appTaskPlan.reason ??
            'الطلب يبدو كأمر تنفيذي مرتبط بالجهاز أو التطبيقات',
        originalText: rawText,
        appTaskPlanResult: appTaskPlan,
      );
    }

    // ================================
    // 4) RECOVERABLE LOCAL APP CASES
    // ================================

    if (_isRecoverableAppTaskPlan(appTaskPlan)) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.appTask,
        message: appTaskPlan.reason ?? 'تم التعرف على الطلب كتفاعل مع التطبيقات',
        originalText: rawText,
        appTaskPlanResult: appTaskPlan,
      );
    }

    // ================================
    // 5) ONLINE AI ONLY AFTER LOCAL FAILS
    // ================================

    final shouldUseOnlineAi =
        await _onlineAiService.shouldUseOnlineAi(normalizedText);

    if (shouldUseOnlineAi || _looksLikeKnowledgeQuestion(normalizedText)) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.onlineAi,
        message: 'تم توجيه الطلب إلى الذكاء عبر الإنترنت',
        originalText: rawText,
        appTaskPlanResult: appTaskPlan,
      );
    }

    // ================================
    // 6) UNKNOWN
    // ================================

    return AssistantRouteResult(
      routeType: AssistantRouteType.unknown,
      message: 'لم يتم تحديد مسار مناسب للطلب',
      originalText: rawText,
      appTaskPlanResult: appTaskPlan,
    );
  }

  // ================================
  // SMALL TALK HEURISTICS
  // ================================

  bool _looksLikeSmallTalk(String text) {
    return _containsAny(
      text,
      const [
        'ازيك',
        'عامل ايه',
        'اخبارك',
        'إخبارك',
        'صباح الخير',
        'مساء الخير',
        'هاي',
        'hello',
        'hi',
        'مرحبا',
        'اهلا',
        'أهلا',
        'صباح النور',
        'مساء النور',
        'مين انت',
        'من انت',
        'انت مين',
      ],
    );
  }

  // ================================
  // KNOWLEDGE / ONLINE AI HEURISTICS
  // ================================

  bool _looksLikeKnowledgeQuestion(String text) {
    return _containsAny(
      text,
      const [
        'ما هو',
        'ما هي',
        'ماهي',
        'مين هو',
        'مين هي',
        'اشرح',
        'فسر',
        'عرفني',
        'معلومة',
        'معلومات',
        'لماذا',
        'ليه',
        'ازاي',
        'كيف',
        'what is',
        'who is',
        'why',
        'how',
        'explain',
        'tell me',
        'summarize',
        'summary',
        'research',
      ],
    );
  }

  // ================================
  // DEVICE / APP ACTION HEURISTICS
  // ================================

  bool _looksLikeDirectDeviceAction(String text) {
    return _containsAny(
      text,
      const [
        'افتح',
        'شغل',
        'شغلي',
        'شغللي',
        'افتحلي',
        'ابعت',
        'ابعتلي',
        'ابعث',
        'ارسل',
        'أرسل',
        'اتصل',
        'كلم',
        'روح',
        'ودي',
        'دوّر في',
        'دور في',
        'افتح المتجر',
        'نزل',
        'ثبت',
        'ارفع الصوت',
        'وطي الصوت',
        'اكتم الصوت',
        'افتح الواي فاي',
        'افتح البلوتوث',
        'افتح الموقع',
        'افتح الاعدادات',
        'open',
        'launch',
        'send',
        'call',
        'install',
        'play',
      ],
    );
  }

  // ================================
  // APP PLAN STATUS HELPER
  // ================================

  bool _isRecoverableAppTaskPlan(AppTaskPlanResult plan) {
    return plan.status == AppTaskPlanStatus.appNotFound ||
        plan.status == AppTaskPlanStatus.unsupportedForApp ||
        plan.status == AppTaskPlanStatus.needsMoreDetails ||
        plan.status == AppTaskPlanStatus.missingTargetApp;
  }

  // ================================
  // HELPERS
  // ================================

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  String _normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[،,.!?؟]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class AssistantRouteResult {
  const AssistantRouteResult({
    required this.routeType,
    required this.message,
    this.originalText,
    this.appTaskPlanResult,
  });

  final AssistantRouteType routeType;
  final String message;
  final String? originalText;
  final AppTaskPlanResult? appTaskPlanResult;

  bool get isValid =>
      routeType != AssistantRouteType.invalid &&
      routeType != AssistantRouteType.unknown;

  bool get isAppTaskRoute => routeType == AssistantRouteType.appTask;
  bool get isOnlineAiRoute => routeType == AssistantRouteType.onlineAi;
  bool get isSmallTalkRoute => routeType == AssistantRouteType.smallTalk;
}

enum AssistantRouteType {
  appTask,
  onlineAi,
  smallTalk,
  unknown,
  invalid,
}

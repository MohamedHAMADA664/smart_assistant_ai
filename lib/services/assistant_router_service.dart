import 'app_task_planner_service.dart';
import 'online_ai_service.dart';

class AssistantRouterService {
  AssistantRouterService({
    AppTaskPlannerService? appTaskPlannerService,
    OnlineAiService? onlineAiService,
  })  : _appTaskPlannerService =
            appTaskPlannerService ?? AppTaskPlannerService(),
        _onlineAiService = onlineAiService ?? OnlineAiService();

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

    if (_looksLikeSmallTalk(normalizedText)) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.smallTalk,
        message: 'تم توجيه الطلب إلى الردود المحلية البسيطة',
        originalText: rawText,
      );
    }

    final appTaskPlan = await _appTaskPlannerService.planFromText(rawText);

    if (appTaskPlan.isReady && appTaskPlan.task != null) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.appTask,
        message: 'تم توجيه الطلب إلى مهام التطبيقات',
        originalText: rawText,
        appTaskPlanResult: appTaskPlan,
      );
    }

    final shouldUseOnlineAi =
        await _onlineAiService.shouldUseOnlineAi(normalizedText);

    if (shouldUseOnlineAi) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.onlineAi,
        message: 'تم توجيه الطلب إلى الذكاء عبر الإنترنت',
        originalText: rawText,
      );
    }

    if (appTaskPlan.status == AppTaskPlanStatus.appNotFound) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.appTask,
        message: appTaskPlan.reason ?? 'تعذر العثور على التطبيق المطلوب',
        originalText: rawText,
        appTaskPlanResult: appTaskPlan,
      );
    }

    if (appTaskPlan.status == AppTaskPlanStatus.unsupportedForApp) {
      return AssistantRouteResult(
        routeType: AssistantRouteType.appTask,
        message: appTaskPlan.reason ?? 'المهمة غير مدعومة لهذا التطبيق',
        originalText: rawText,
        appTaskPlanResult: appTaskPlan,
      );
    }

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
        'صباح الخير',
        'مساء الخير',
        'هاي',
        'hello',
        'hi',
        'مرحبا',
        'اهلا',
        'أهلا',
      ],
    );
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  String _normalize(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
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

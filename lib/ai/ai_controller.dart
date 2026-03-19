import '../services/app_task_executor_service.dart';
import '../services/assistant_router_service.dart';
import '../services/online_ai_service.dart';
import '../services/openai_gateway.dart';
import '../services/voice_response_service.dart';

class AIController {
  AIController({
    AssistantRouterService? assistantRouterService,
    AppTaskExecutorService? appTaskExecutorService,
    OnlineAiService? onlineAiService,
    VoiceResponseService? voiceResponseService,
  })  : _router = assistantRouterService ?? AssistantRouterService(),
        _executor = appTaskExecutorService ?? AppTaskExecutorService(),
        _onlineAiService = onlineAiService ??
            OnlineAiService(
              gateway: OpenAiGateway(),
            ),
        _voice = voiceResponseService ?? VoiceResponseService();

  final AssistantRouterService _router;
  final AppTaskExecutorService _executor;
  final OnlineAiService _onlineAiService;
  final VoiceResponseService _voice;

  bool _isInitialized = false;

  // =========================
  // INITIALIZE
  // =========================

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _voice.initialize();
    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // =========================
  // MAIN ENTRY
  // =========================

  Future<AIProcessResult> processVoice(String speechText) async {
    await _ensureInitialized();

    final cleanText = _normalize(speechText);

    if (cleanText.isEmpty) {
      return const AIProcessResult.ignored();
    }

    final routeResult = await _router.route(cleanText);

    switch (routeResult.routeType) {
      case AssistantRouteType.smallTalk:
        return _handleSmallTalk(cleanText);

      case AssistantRouteType.appTask:
        return _handleAppTaskRoute(routeResult, cleanText);

      case AssistantRouteType.onlineAi:
        return _handleOnlineAiRoute(cleanText);

      case AssistantRouteType.unknown:
        return _handleUnknown(cleanText);

      case AssistantRouteType.invalid:
        return const AIProcessResult.ignored();
    }
  }

  // =========================
  // SMALL TALK
  // =========================

  Future<AIProcessResult> _handleSmallTalk(String text) async {
    final response = _generateSmallTalkResponse(text);

    await _voice.speak(response);

    return AIProcessResult(
      handled: true,
      routeType: AIHandledRouteType.smallTalk,
      message: response,
    );
  }

  // =========================
  // APP TASKS
  // =========================

  Future<AIProcessResult> _handleAppTaskRoute(
    AssistantRouteResult routeResult,
    String originalText,
  ) async {
    final planResult = routeResult.appTaskPlanResult;

    if (planResult == null) {
      final fallback = _generateFallbackResponse(originalText);
      await _voice.speak(fallback);

      return AIProcessResult(
        handled: false,
        routeType: AIHandledRouteType.appTask,
        message: fallback,
      );
    }

    if (!planResult.isReady || planResult.task == null) {
      final message = planResult.reason ?? _generateFallbackResponse(originalText);

      await _voice.speak(message);

      return AIProcessResult(
        handled: false,
        routeType: AIHandledRouteType.appTask,
        message: message,
      );
    }

    final executionResult = await _executor.executePlan(planResult);

    await _voice.speak(executionResult.message);

    return AIProcessResult(
      handled: executionResult.isSuccess,
      routeType: AIHandledRouteType.appTask,
      message: executionResult.message,
    );
  }

  // =========================
  // ONLINE AI
  // =========================

  Future<AIProcessResult> _handleOnlineAiRoute(String text) async {
    final result = await _onlineAiService.askQuestion(text);

    if (!result.isSuccess || result.answer == null || result.answer!.isEmpty) {
      await _voice.speak(result.message);

      return AIProcessResult(
        handled: false,
        routeType: AIHandledRouteType.onlineAi,
        message: result.message,
      );
    }

    await _voice.speak(result.answer!);

    return AIProcessResult(
      handled: true,
      routeType: AIHandledRouteType.onlineAi,
      message: result.answer!,
    );
  }

  // =========================
  // UNKNOWN / FALLBACK
  // =========================

  Future<AIProcessResult> _handleUnknown(String text) async {
    final fallbackResponse = _generateFallbackResponse(text);

    await _voice.speak(fallbackResponse);

    return AIProcessResult(
      handled: false,
      routeType: AIHandledRouteType.unknown,
      message: fallbackResponse,
    );
  }

  // =========================
  // LOCAL SMALL TALK RESPONSES
  // =========================

  String _generateSmallTalkResponse(String text) {
    if (_containsAny(text, const ['ازيك', 'عامل ايه', 'اخبارك'])) {
      return 'أنا بخير، كيف أساعدك؟';
    }

    if (_containsAny(text, const ['صباح الخير'])) {
      return 'صباح النور';
    }

    if (_containsAny(text, const ['مساء الخير'])) {
      return 'مساء النور';
    }

    if (_containsAny(
      text,
      const ['اهلا', 'أهلا', 'مرحبا', 'هاي', 'hello', 'hi'],
    )) {
      return 'أهلًا بك، كيف أساعدك؟';
    }

    return 'أنا معك';
  }

  // =========================
  // FALLBACK RESPONSES
  // =========================

  String _generateFallbackResponse(String text) {
    if (_containsAny(text, const ['افتح', 'شغل', 'افتحلي'])) {
      return 'فهمت أنك تريد فتح تطبيق، لكن لم أتعرف على التطبيق المطلوب بدقة';
    }

    if (_containsAny(text, const ['ابعت', 'ابعث', 'ارسل', 'أرسل'])) {
      return 'فهمت أنك تريد إرسال شيء، لكن ما زلت أحتاج تفاصيل أكثر';
    }

    if (_containsAny(text, const ['اتصل', 'كلم'])) {
      return 'فهمت أنك تريد إجراء اتصال، لكن أحتاج تفاصيل أكثر';
    }

    if (_containsAny(text, const ['ابحث', 'دور', 'search'])) {
      return 'فهمت أنك تريد البحث، لكني أحتاج تفاصيل أوضح';
    }

    return 'لم أفهم المهمة بشكل كافٍ';
  }

  // =========================
  // HELPERS
  // =========================

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
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[،,.!?؟]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class AIProcessResult {
  const AIProcessResult({
    required this.handled,
    required this.routeType,
    required this.message,
  });

  const AIProcessResult.ignored()
      : handled = false,
        routeType = AIHandledRouteType.ignored,
        message = '';

  final bool handled;
  final AIHandledRouteType routeType;
  final String message;

  bool get isIgnored => routeType == AIHandledRouteType.ignored;
}

enum AIHandledRouteType {
  appTask,
  onlineAi,
  smallTalk,
  unknown,
  ignored,
}

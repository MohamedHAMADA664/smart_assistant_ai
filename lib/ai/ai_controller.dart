import '../services/app_task_executor_service.dart';
import '../services/assistant_router_service.dart';
import '../services/online_ai_service.dart';
import '../services/voice_response_service.dart';

class AIController {
  AIController({
    AssistantRouterService? assistantRouterService,
    AppTaskExecutorService? appTaskExecutorService,
    OnlineAiService? onlineAiService,
    VoiceResponseService? voiceResponseService,
  })  : _router = assistantRouterService ?? AssistantRouterService(),
        _executor = appTaskExecutorService ?? AppTaskExecutorService(),
        _onlineAiService = onlineAiService ?? OnlineAiService(),
        _voice = voiceResponseService ?? VoiceResponseService();

  final AssistantRouterService _router;
  final AppTaskExecutorService _executor;
  final OnlineAiService _onlineAiService;
  final VoiceResponseService _voice;

  Future<AIProcessResult> processVoice(String speechText) async {
    final cleanText = _normalize(speechText);

    if (cleanText.isEmpty) {
      return const AIProcessResult.ignored();
    }

    final routeResult = await _router.route(cleanText);

    switch (routeResult.routeType) {
      case AssistantRouteType.smallTalk:
        return _handleSmallTalk(cleanText);

      case AssistantRouteType.appTask:
        return _handleAppTaskRoute(routeResult);

      case AssistantRouteType.onlineAi:
        return _handleOnlineAiRoute(cleanText);

      case AssistantRouteType.unknown:
        await _voice.speak('لم أفهم الطلب بشكل كافٍ');
        return const AIProcessResult(
          handled: false,
          routeType: AIHandledRouteType.unknown,
          message: 'تعذر تحديد المسار المناسب للطلب',
        );

      case AssistantRouteType.invalid:
        return const AIProcessResult.ignored();
    }
  }

  Future<AIProcessResult> _handleSmallTalk(String text) async {
    final response = _generateSmallTalkResponse(text);

    await _voice.speak(response);

    return AIProcessResult(
      handled: true,
      routeType: AIHandledRouteType.smallTalk,
      message: response,
    );
  }

  Future<AIProcessResult> _handleAppTaskRoute(
    AssistantRouteResult routeResult,
  ) async {
    final planResult = routeResult.appTaskPlanResult;

    if (planResult == null) {
      await _voice.speak('تعذر تجهيز المهمة المطلوبة');
      return const AIProcessResult(
        handled: false,
        routeType: AIHandledRouteType.appTask,
        message: 'لا توجد خطة تنفيذ متاحة',
      );
    }

    if (!planResult.isReady || planResult.task == null) {
      final message = planResult.reason ?? 'تعذر تجهيز المهمة المطلوبة';

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

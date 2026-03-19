import 'dart:async';

import 'assistant_profile_service.dart';

class OnlineAiService {
  OnlineAiService({
    AssistantProfileService? assistantProfileService,
    OnlineAiGateway? gateway,
  })  : _assistantProfileService =
            assistantProfileService ?? AssistantProfileService(),
        _gateway = gateway;

  final AssistantProfileService _assistantProfileService;
  final OnlineAiGateway? _gateway;

  // ================================
  // CHECK IF ONLINE AI IS ENABLED
  // ================================

  Future<bool> isEnabled() async {
    final profile = await _assistantProfileService.loadProfile();
    return profile.onlineAiEnabled;
  }

  // ================================
  // SHOULD USE ONLINE AI
  // ================================

  Future<bool> shouldUseOnlineAi(String text) async {
    final normalizedText = _normalize(text);

    if (normalizedText.isEmpty) {
      return false;
    }

    final enabled = await isEnabled();
    if (!enabled) {
      return false;
    }

    return _looksLikeGeneralQuestion(normalizedText);
  }

  // ================================
  // ASK ONLINE AI
  // ================================

  Future<OnlineAiResult> askQuestion(
    String text, {
    String? conversationContext,
  }) async {
    final normalizedText = _normalize(text);

    if (normalizedText.isEmpty) {
      return const OnlineAiResult(
        status: OnlineAiStatus.invalidInput,
        message: 'النص المدخل فارغ',
      );
    }

    final enabled = await isEnabled();
    if (!enabled) {
      return const OnlineAiResult(
        status: OnlineAiStatus.disabled,
        message: 'الذكاء عبر الإنترنت غير مفعّل',
      );
    }

    if (_gateway == null) {
      return const OnlineAiResult(
        status: OnlineAiStatus.notConfigured,
        message: 'لم يتم إعداد مزود الذكاء عبر الإنترنت بعد',
      );
    }

    try {
      final response = await _gateway!.generateResponse(
        OnlineAiRequest(
          prompt: normalizedText,
          context: conversationContext?.trim(),
        ),
      );

      final normalizedAnswer = response.text.trim();
      if (normalizedAnswer.isEmpty) {
        return const OnlineAiResult(
          status: OnlineAiStatus.failed,
          message: 'لم يتم الحصول على رد صالح من الذكاء عبر الإنترنت',
        );
      }

      return OnlineAiResult(
        status: OnlineAiStatus.success,
        message: 'تم الحصول على رد من الذكاء عبر الإنترنت',
        answer: normalizedAnswer,
        source: response.source,
        model: response.model,
      );
    } on TimeoutException {
      return const OnlineAiResult(
        status: OnlineAiStatus.timeout,
        message: 'انتهت مهلة انتظار الرد من الذكاء عبر الإنترنت',
      );
    } catch (_) {
      return const OnlineAiResult(
        status: OnlineAiStatus.failed,
        message: 'حدث خطأ أثناء التواصل مع الذكاء عبر الإنترنت',
      );
    }
  }

  // ================================
  // QUESTION HEURISTICS
  // ================================

  bool _looksLikeGeneralQuestion(String text) {
    if (_containsAny(
      text,
      const [
        'مين',
        'ما هو',
        'ماهي',
        'اشرح',
        'فسر',
        'عرفني',
        'احكيلي',
        'قوللي',
        'why',
        'what',
        'who',
        'when',
        'where',
        'how',
        'explain',
      ],
    )) {
      return true;
    }

    if (text.endsWith('?') || text.endsWith('؟')) {
      return true;
    }

    if (_containsAny(
      text,
      const [
        'اكتبلي',
        'اكتب لي',
        'لخص',
        'تلخيص',
        'اقترح',
        'ساعدني في',
        'هاتلي فكرة',
        'اعمل لي',
      ],
    )) {
      return true;
    }

    return false;
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
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

abstract class OnlineAiGateway {
  Future<OnlineAiGatewayResponse> generateResponse(
    OnlineAiRequest request,
  );
}

class OnlineAiRequest {
  const OnlineAiRequest({
    required this.prompt,
    this.context,
  });

  final String prompt;
  final String? context;
}

class OnlineAiGatewayResponse {
  const OnlineAiGatewayResponse({
    required this.text,
    this.source,
    this.model,
  });

  final String text;
  final String? source;
  final String? model;
}

class OnlineAiResult {
  const OnlineAiResult({
    required this.status,
    required this.message,
    this.answer,
    this.source,
    this.model,
  });

  final OnlineAiStatus status;
  final String message;
  final String? answer;
  final String? source;
  final String? model;

  bool get isSuccess => status == OnlineAiStatus.success;
}

enum OnlineAiStatus {
  success,
  disabled,
  notConfigured,
  invalidInput,
  timeout,
  failed,
}

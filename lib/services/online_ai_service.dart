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

  bool get hasGateway => _gateway != null;

  // ================================
  // CHECK IF ONLINE AI IS ENABLED
  // ================================

  Future<bool> isEnabled() async {
    final profile = await _assistantProfileService.loadProfile();
    return profile.onlineAiEnabled;
  }

  // ================================
  // CHECK IF ONLINE AI CAN ANSWER
  // ================================

  Future<bool> canAnswerOnline(String text) async {
    final enabled = await isEnabled();
    if (!enabled) {
      return false;
    }

    if (_gateway == null) {
      return false;
    }

    final normalizedText = _normalize(text);
    if (normalizedText.isEmpty) {
      return false;
    }

    return true;
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

    return _looksLikeGeneralQuestion(normalizedText) ||
        _looksLikeCreativeRequest(normalizedText) ||
        _looksLikeKnowledgeRequest(normalizedText);
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
          context: _normalizeOptionalContext(conversationContext),
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
        source: _normalizeOptionalField(response.source),
        model: _normalizeOptionalField(response.model),
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
        'ما هي',
        'ماهي',
        'اشرح',
        'فسر',
        'عرفني',
        'احكيلي',
        'احكي لي',
        'قوللي',
        'قول لي',
        'قل لي',
        'ليه',
        'لماذا',
        'كيف',
        'ازاي',
        'why',
        'what',
        'who',
        'when',
        'where',
        'how',
        'explain',
        'tell me',
      ],
    )) {
      return true;
    }

    if (text.endsWith('?') || text.endsWith('؟')) {
      return true;
    }

    return false;
  }

  bool _looksLikeCreativeRequest(String text) {
    return _containsAny(
      text,
      const [
        'اكتبلي',
        'اكتب لي',
        'لخص',
        'تلخيص',
        'اقترح',
        'ساعدني في',
        'هاتلي فكرة',
        'هات لي فكرة',
        'اعمل لي',
        'اكتب رسالة',
        'اكتب ايميل',
        'اكتب منشور',
        'اكتب بوست',
        'write',
        'summarize',
        'suggest',
        'draft',
      ],
    );
  }

  bool _looksLikeKnowledgeRequest(String text) {
    return _containsAny(
      text,
      const [
        'معلومة',
        'معلومات',
        'بحث',
        'ابحث عن',
        'ابحثلي عن',
        'ابحث لي عن',
        'خبر',
        'اخبار',
        'أخبار',
        'موضوع عن',
        'تفاصيل عن',
        'search for',
        'news about',
        'information about',
      ],
    );
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

  String? _normalizeOptionalContext(String? text) {
    if (text == null) {
      return null;
    }

    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  String? _normalizeOptionalField(String? text) {
    if (text == null) {
      return null;
    }

    final normalized = text.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
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
  bool get isRecoverable =>
      status == OnlineAiStatus.timeout || status == OnlineAiStatus.failed;
  bool get isUnavailable =>
      status == OnlineAiStatus.disabled ||
      status == OnlineAiStatus.notConfigured;
}

enum OnlineAiStatus {
  success,
  disabled,
  notConfigured,
  invalidInput,
  timeout,
  failed,
}

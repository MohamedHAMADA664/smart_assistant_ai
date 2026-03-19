import 'dart:async';
import 'dart:convert';

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

    if (_looksLikeDirectExecutionCommand(normalizedText)) {
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

    if (_gateway == null) {
      return false;
    }

    // مهم جدًا:
    // الأوامر المحلية التنفيذية لا يجب أن تذهب للأونلاين AI
    if (_looksLikeDirectExecutionCommand(normalizedText)) {
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
          prompt: _buildAnswerPrompt(normalizedText),
          context: _normalizeOptionalContext(conversationContext),
          mode: OnlineAiRequestMode.answer,
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
    } catch (e) {
      return OnlineAiResult(
        status: OnlineAiStatus.failed,
        message: 'حدث خطأ أثناء التواصل مع الذكاء عبر الإنترنت: $e',
      );
    }
  }

  // ================================
  // SUGGEST COMMAND EXECUTION
  // ================================

  Future<OnlineAiSuggestedCommandPlan> suggestCommandExecution(
    String text, {
    String? conversationContext,
  }) async {
    final normalizedText = _normalize(text);

    if (normalizedText.isEmpty) {
      return const OnlineAiSuggestedCommandPlan(
        status: OnlineAiSuggestionStatus.invalidInput,
        message: 'النص المدخل فارغ',
      );
    }

    final enabled = await isEnabled();
    if (!enabled) {
      return const OnlineAiSuggestedCommandPlan(
        status: OnlineAiSuggestionStatus.disabled,
        message: 'الذكاء عبر الإنترنت غير مفعّل',
      );
    }

    if (_gateway == null) {
      return const OnlineAiSuggestedCommandPlan(
        status: OnlineAiSuggestionStatus.notConfigured,
        message: 'لم يتم إعداد مزود الذكاء عبر الإنترنت بعد',
      );
    }

    try {
      final response = await _gateway!.generateResponse(
        OnlineAiRequest(
          prompt: _buildCommandPlanningPrompt(normalizedText),
          context: _normalizeOptionalContext(conversationContext),
          mode: OnlineAiRequestMode.commandPlanning,
        ),
      );

      final rawText = response.text.trim();
      if (rawText.isEmpty) {
        return const OnlineAiSuggestedCommandPlan(
          status: OnlineAiSuggestionStatus.failed,
          message: 'الذكاء عبر الإنترنت لم يرجع تخطيطًا صالحًا',
        );
      }

      final jsonObject = _extractJsonObject(rawText);
      if (jsonObject == null) {
        return OnlineAiSuggestedCommandPlan(
          status: OnlineAiSuggestionStatus.failed,
          message: 'تعذر قراءة تخطيط الأمر من الرد',
          rawResponse: rawText,
          source: _normalizeOptionalField(response.source),
          model: _normalizeOptionalField(response.model),
        );
      }

      final intent = _parseIntent(
        jsonObject['intent']?.toString(),
      );

      final confidence = _parseConfidence(jsonObject['confidence']);
      final requiresConfirmation =
          _parseBool(jsonObject['requires_confirmation']);
      final appName = _normalizeOptionalField(
        jsonObject['app_name']?.toString(),
      );
      final contactName = _normalizeOptionalField(
        jsonObject['contact_name']?.toString(),
      );
      final messageText = _normalizeOptionalField(
        jsonObject['message_text']?.toString(),
      );
      final searchQuery = _normalizeOptionalField(
        jsonObject['search_query']?.toString(),
      );
      final storeAppName = _normalizeOptionalField(
        jsonObject['store_app_name']?.toString(),
      );
      final serverName = _normalizeOptionalField(
        jsonObject['server_name']?.toString(),
      );
      final answer = _normalizeOptionalField(
        jsonObject['answer']?.toString(),
      );
      final notes = _normalizeOptionalField(
        jsonObject['notes']?.toString(),
      );

      return OnlineAiSuggestedCommandPlan(
        status: OnlineAiSuggestionStatus.success,
        message: 'تم تفسير الأمر بواسطة الذكاء عبر الإنترنت',
        intent: intent,
        confidence: confidence,
        requiresConfirmation: requiresConfirmation,
        appName: appName,
        contactName: contactName,
        messageText: messageText,
        searchQuery: searchQuery,
        storeAppName: storeAppName,
        serverName: serverName,
        answer: answer,
        notes: notes,
        rawResponse: rawText,
        source: _normalizeOptionalField(response.source),
        model: _normalizeOptionalField(response.model),
      );
    } on TimeoutException {
      return const OnlineAiSuggestedCommandPlan(
        status: OnlineAiSuggestionStatus.timeout,
        message: 'انتهت مهلة تفسير الأمر عبر الإنترنت',
      );
    } catch (e) {
      return OnlineAiSuggestedCommandPlan(
        status: OnlineAiSuggestionStatus.failed,
        message: 'حدث خطأ أثناء تفسير الأمر عبر الإنترنت: $e',
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

  bool _looksLikeDirectExecutionCommand(String text) {
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
  // PROMPTS
  // ================================

  String _buildAnswerPrompt(String text) {
    return '''
أجب على المستخدم بإجابة مفيدة ومختصرة وواضحة.
إذا كان السؤال مباشرًا فأجب مباشرة.
إذا احتاج تنسيقًا بسيطًا فحافظ على البساطة.
سؤال المستخدم:
$text
''';
  }

  String _buildCommandPlanningPrompt(String text) {
    return '''
حلل أمر المستخدم وحوّله إلى JSON فقط بدون أي شرح إضافي.
أعد كائن JSON واحد فقط بالشكل التالي:

{
  "intent": "open_app | open_chat | prepare_message | search_in_app | search_store | open_store_listing | install_app | connect_vpn | disconnect_vpn | open_settings | web_search | general_answer | unsupported",
  "confidence": 0.0,
  "requires_confirmation": false,
  "app_name": null,
  "contact_name": null,
  "message_text": null,
  "search_query": null,
  "store_app_name": null,
  "server_name": null,
  "answer": null,
  "notes": null
}

قواعد مهمة:
- إذا كان الأمر متعلقًا بفتح تطبيق فاختر open_app.
- إذا كان متعلقًا بفتح دردشة فاختر open_chat.
- إذا كان متعلقًا بتجهيز رسالة فاختر prepare_message.
- إذا كان متعلقًا بالبحث داخل تطبيق فاختر search_in_app.
- إذا كان متعلقًا بالمتجر فاختر search_store أو open_store_listing أو install_app.
- إذا كان متعلقًا بـ VPN فاختر connect_vpn أو disconnect_vpn.
- إذا كان مجرد سؤال عام فاختر general_answer وضع الرد في answer.
- إذا لم يكن واضحًا أو غير قابل للتنفيذ فاختر unsupported.
- confidence رقم بين 0 و 1.
- أعد JSON فقط.

أمر المستخدم:
$text
''';
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

  Map<String, dynamic>? _extractJsonObject(String rawText) {
    final trimmed = rawText.trim();

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {
      // Continue with block extraction
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');

    if (start >= 0 && end > start) {
      final candidate = trimmed.substring(start, end + 1);
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  OnlineAiSuggestedIntent _parseIntent(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();

    switch (normalized) {
      case 'open_app':
        return OnlineAiSuggestedIntent.openApp;
      case 'open_chat':
        return OnlineAiSuggestedIntent.openChat;
      case 'prepare_message':
        return OnlineAiSuggestedIntent.prepareMessage;
      case 'search_in_app':
        return OnlineAiSuggestedIntent.searchInApp;
      case 'search_store':
        return OnlineAiSuggestedIntent.searchStore;
      case 'open_store_listing':
        return OnlineAiSuggestedIntent.openStoreListing;
      case 'install_app':
        return OnlineAiSuggestedIntent.installApp;
      case 'connect_vpn':
        return OnlineAiSuggestedIntent.connectVpn;
      case 'disconnect_vpn':
        return OnlineAiSuggestedIntent.disconnectVpn;
      case 'open_settings':
        return OnlineAiSuggestedIntent.openSettings;
      case 'web_search':
        return OnlineAiSuggestedIntent.webSearch;
      case 'general_answer':
        return OnlineAiSuggestedIntent.generalAnswer;
      default:
        return OnlineAiSuggestedIntent.unsupported;
    }
  }

  double _parseConfidence(dynamic value) {
    if (value is num) {
      return value.clamp(0.0, 1.0).toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed.clamp(0.0, 1.0).toDouble();
      }
    }

    return 0.0;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'نعم';
    }

    return false;
  }
}

abstract class OnlineAiGateway {
  Future<OnlineAiGatewayResponse> generateResponse(
    OnlineAiRequest request,
  );
}

enum OnlineAiRequestMode {
  answer,
  commandPlanning,
}

class OnlineAiRequest {
  const OnlineAiRequest({
    required this.prompt,
    this.context,
    this.mode = OnlineAiRequestMode.answer,
  });

  final String prompt;
  final String? context;
  final OnlineAiRequestMode mode;
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

class OnlineAiSuggestedCommandPlan {
  const OnlineAiSuggestedCommandPlan({
    required this.status,
    required this.message,
    this.intent = OnlineAiSuggestedIntent.unsupported,
    this.confidence = 0.0,
    this.requiresConfirmation = false,
    this.appName,
    this.contactName,
    this.messageText,
    this.searchQuery,
    this.storeAppName,
    this.serverName,
    this.answer,
    this.notes,
    this.rawResponse,
    this.source,
    this.model,
  });

  final OnlineAiSuggestionStatus status;
  final String message;
  final OnlineAiSuggestedIntent intent;
  final double confidence;
  final bool requiresConfirmation;
  final String? appName;
  final String? contactName;
  final String? messageText;
  final String? searchQuery;
  final String? storeAppName;
  final String? serverName;
  final String? answer;
  final String? notes;
  final String? rawResponse;
  final String? source;
  final String? model;

  bool get isSuccess => status == OnlineAiSuggestionStatus.success;
}

enum OnlineAiSuggestionStatus {
  success,
  disabled,
  notConfigured,
  invalidInput,
  timeout,
  failed,
}

enum OnlineAiSuggestedIntent {
  openApp,
  openChat,
  prepareMessage,
  searchInApp,
  searchStore,
  openStoreListing,
  installApp,
  connectVpn,
  disconnectVpn,
  openSettings,
  webSearch,
  generalAnswer,
  unsupported,
}

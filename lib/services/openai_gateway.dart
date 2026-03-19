import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'online_ai_service.dart';

class OpenAiGateway implements OnlineAiGateway {
  OpenAiGateway({
    http.Client? client,
    Duration timeout = const Duration(seconds: 25),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  final String apiKey = const String.fromEnvironment('OPENAI_API_KEY');
  final String model = const String.fromEnvironment('OPENAI_MODEL');
  final String baseUrl = const String.fromEnvironment('OPENAI_BASE_URL');

  @override
  Future<OnlineAiGatewayResponse> generateResponse(
    OnlineAiRequest request,
  ) async {
    final normalizedPrompt = request.prompt.trim();

    if (normalizedPrompt.isEmpty) {
      throw Exception('OpenAI prompt is empty.');
    }

    final normalizedApiKey = apiKey.trim();
    final normalizedModel = model.trim();
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);

    if (normalizedApiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY is missing.');
    }

    if (normalizedModel.isEmpty) {
      throw Exception('OPENAI_MODEL is missing.');
    }

    if (normalizedBaseUrl.isEmpty) {
      throw Exception('OPENAI_BASE_URL is missing.');
    }

    final url = Uri.parse('$normalizedBaseUrl/chat/completions');

    final payload = <String, dynamic>{
      'model': normalizedModel,
      'messages': [
        {
          'role': 'system',
          'content': _buildSystemPrompt(
            mode: request.mode,
            context: request.context,
          ),
        },
        {
          'role': 'user',
          'content': normalizedPrompt,
        },
      ],
      'temperature': request.mode == OnlineAiRequestMode.commandPlanning
          ? 0.1
          : 0.3,
    };

    http.Response response;

    try {
      response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $normalizedApiKey',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw TimeoutException('OpenAI request timed out.');
    } catch (e) {
      throw Exception('Failed to connect to OpenAI: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }

    final dynamic data = _safeDecodeJson(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('OpenAI returned an invalid JSON response.');
    }

    final String text = _extractAssistantText(data).trim();

    if (text.isEmpty) {
      throw Exception('OpenAI returned an empty response.');
    }

    final responseModel = _extractResponseModel(data) ?? normalizedModel;

    return OnlineAiGatewayResponse(
      text: text,
      source: 'openai',
      model: responseModel,
    );
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }

  String _buildSystemPrompt({
    required OnlineAiRequestMode mode,
    String? context,
  }) {
    final buffer = StringBuffer();

    if (mode == OnlineAiRequestMode.commandPlanning) {
      buffer.writeln(
        'أنت مساعد تخطيط أوامر داخل تطبيق موبايل عربي.',
      );
      buffer.writeln(
        'مهمتك تحويل طلب المستخدم إلى JSON دقيق فقط بدون أي شرح إضافي.',
      );
      buffer.writeln(
        'لا تضف markdown ولا تعليقات ولا مقدمة ولا خاتمة.',
      );
      buffer.writeln(
        'إذا لم تفهم الأمر بدقة فأعد intent = unsupported.',
      );
    } else {
      buffer.writeln(
        'أنت مساعد ذكي داخل تطبيق موبايل عربي.',
      );
      buffer.writeln(
        'أجب بإجابة واضحة ومفيدة ومباشرة وبأسلوب مختصر.',
      );
      buffer.writeln(
        'لا تطل بدون داعٍ، وركز على تلبية طلب المستخدم مباشرة.',
      );
    }

    final normalizedContext = context?.trim();
    if (normalizedContext != null && normalizedContext.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('السياق الحالي:')
        ..writeln(normalizedContext);
    }

    return buffer.toString().trim();
  }

  dynamic _safeDecodeJson(String rawBody) {
    try {
      return jsonDecode(rawBody);
    } catch (e) {
      throw Exception('Failed to parse OpenAI JSON response: $e');
    }
  }

  String _extractAssistantText(Map<String, dynamic> data) {
    final choices = data['choices'];

    if (choices is! List || choices.isEmpty) {
      return '';
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map) {
      return '';
    }

    final normalizedChoice = firstChoice.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final message = normalizedChoice['message'];
    if (message is! Map) {
      return '';
    }

    final normalizedMessage = message.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final content = normalizedMessage['content'];

    if (content is String) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();

      for (final item in content) {
        if (item is Map) {
          final normalizedItem = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );

          final type = normalizedItem['type'];
          if (type == 'text') {
            final textValue = normalizedItem['text'];

            if (textValue is String && textValue.trim().isNotEmpty) {
              if (buffer.isNotEmpty) {
                buffer.writeln();
              }
              buffer.write(textValue.trim());
            }
          }
        }
      }

      return buffer.toString().trim();
    }

    return '';
  }

  String? _extractResponseModel(Map<String, dynamic> data) {
    final value = data['model'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final dynamic data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final error = data['error'];

        if (error is Map<String, dynamic>) {
          final message = error['message'];
          final type = error['type'];
          final code = error['code'];

          final parts = <String>[];

          if (message is String && message.trim().isNotEmpty) {
            parts.add(message.trim());
          }

          if (type is String && type.trim().isNotEmpty) {
            parts.add('type=${type.trim()}');
          }

          if (code is String && code.trim().isNotEmpty) {
            parts.add('code=${code.trim()}');
          }

          if (parts.isNotEmpty) {
            return 'OpenAI error ${response.statusCode}: ${parts.join(' | ')}';
          }
        }
      }
    } catch (_) {
      // تجاهل وفكك للـ fallback
    }

    final rawBody = response.body.trim();
    if (rawBody.isEmpty) {
      return 'OpenAI error ${response.statusCode}.';
    }

    return 'OpenAI error ${response.statusCode}: $rawBody';
  }
}

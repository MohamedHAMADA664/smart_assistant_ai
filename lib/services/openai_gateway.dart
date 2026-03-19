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
      throw Exception('Prompt is empty.');
    }

    if (apiKey.trim().isEmpty) {
      throw Exception('OPENAI_API_KEY is missing.');
    }

    if (model.trim().isEmpty) {
      throw Exception('OPENAI_MODEL is missing.');
    }

    if (baseUrl.trim().isEmpty) {
      throw Exception('OPENAI_BASE_URL is missing.');
    }

    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    final url = Uri.parse('$normalizedBaseUrl/chat/completions');

    final response = await _client
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'system',
                'content': _buildSystemPrompt(
                  context: request.context,
                ),
              },
              {
                'role': 'user',
                'content': normalizedPrompt,
              },
            ],
            'temperature': 0.3,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }

    final dynamic data = jsonDecode(response.body);

    final String text = _extractAssistantText(data);

    if (text.trim().isEmpty) {
      throw Exception('OpenAI returned an empty response.');
    }

    return OnlineAiGatewayResponse(
      text: text.trim(),
      source: 'openai',
      model: model,
    );
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String _buildSystemPrompt({String? context}) {
    final buffer = StringBuffer()
      ..writeln(
        'أنت مساعد ذكي داخل تطبيق موبايل عربي.',
      )
      ..writeln(
        'مهمتك فهم أوامر المستخدم وتحويلها إلى رد واضح ومفيد ومباشر.',
      )
      ..writeln(
        'لو كان الطلب عمليًا متعلقًا بتطبيقات أو الجهاز، فافهم نية المستخدم بدقة.',
      )
      ..writeln(
        'لا تكتب مقدمات طويلة، واجعل الرد مختصرًا وواضحًا.',
      );

    final normalizedContext = context?.trim();
    if (normalizedContext != null && normalizedContext.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('السياق الحالي:')
        ..writeln(normalizedContext);
    }

    return buffer.toString().trim();
  }

  String _extractAssistantText(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return '';
    }

    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      return '';
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      return '';
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      return '';
    }

    final content = message['content'];

    if (content is String) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();

      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final type = item['type'];
          if (type == 'text') {
            final text = item['text'];
            if (text is String && text.trim().isNotEmpty) {
              if (buffer.isNotEmpty) {
                buffer.writeln();
              }
              buffer.write(text.trim());
            }
          }
        }
      }

      return buffer.toString().trim();
    }

    return '';
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final dynamic data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final error = data['error'];

        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return 'OpenAI error ${response.statusCode}: ${message.trim()}';
          }
        }
      }
    } catch (_) {
      // Ignore JSON parsing issues and fall back to raw body.
    }

    final rawBody = response.body.trim();
    if (rawBody.isEmpty) {
      return 'OpenAI error ${response.statusCode}.';
    }

    return 'OpenAI error ${response.statusCode}: $rawBody';
  }
}

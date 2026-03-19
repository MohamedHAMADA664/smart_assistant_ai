import 'dart:convert';
import 'package:http/http.dart' as http;

import 'online_ai_service.dart';

class OpenAiGateway implements OnlineAiGateway {
  final String apiKey = const String.fromEnvironment('OPENAI_API_KEY');
  final String model = const String.fromEnvironment('OPENAI_MODEL');
  final String baseUrl = const String.fromEnvironment('OPENAI_BASE_URL');

  @override
  Future<OnlineAiGatewayResponse> generateResponse(
    OnlineAiRequest request,
  ) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": model,
        "messages": [
          {
            "role": "system",
            "content":
                "أنت مساعد ذكي داخل تطبيق موبايل. مهمتك فهم أوامر المستخدم وتحويلها لأفعال واضحة وقابلة للتنفيذ داخل التطبيقات."
          },
          {
            "role": "user",
            "content": request.prompt,
          }
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI error: ${response.body}');
    }

    final data = jsonDecode(response.body);

    final text =
        data['choices'][0]['message']['content'] ?? '';

    return OnlineAiGatewayResponse(
      text: text,
      source: 'openai',
      model: model,
    );
  }
}

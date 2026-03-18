import 'package:flutter/services.dart';
import 'voice_response_service.dart';

class CallHandlerService {
  static const MethodChannel _channel = MethodChannel("call_channel");

  final VoiceResponseService _voice = VoiceResponseService();

  void init() {
    _channel.setMethodCallHandler((call) async {
      try {
        if (call.method == "incoming_call") {
          String number = call.arguments ?? "رقم غير معروف";

          // 🔥 يتكلم لما المكالمة تيجي
          await _voice.speak("فيه مكالمة من $number هل تريد الرد؟");
        }
      } catch (e) {
        print("CallHandler error: $e");
      }
    });
  }
}

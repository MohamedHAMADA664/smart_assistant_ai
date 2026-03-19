import 'package:flutter/services.dart';

import 'voice_response_service.dart';

@Deprecated(
  'Use VoiceListenerService native call event handling instead. '
  'This class is kept temporarily for backward compatibility.',
)
class CallHandlerService {
  CallHandlerService({
    VoiceResponseService? voiceResponseService,
  }) : _voice = voiceResponseService ?? VoiceResponseService();

  static const MethodChannel _channel =
      MethodChannel('smart_assistant/call_events');

  final VoiceResponseService _voice;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _channel.setMethodCallHandler((call) async {
      try {
        if (call.method != 'incomingCall') {
          return;
        }

        final number = (call.arguments as String?)?.trim();
        final displayNumber =
            (number == null || number.isEmpty) ? 'رقم غير معروف' : number;

        await _voice.speak('فيه مكالمة من $displayNumber هل تريد الرد؟');
      } catch (_) {
        // Ignore compatibility handler errors silently.
      }
    });

    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }

    _channel.setMethodCallHandler(null);
    _initialized = false;
  }
}

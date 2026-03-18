import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class CallControlService {
  final Logger _logger = Logger();

  static const MethodChannel _channel =
      MethodChannel('smart_assistant/call_control');

  // ==========================
  // ANSWER CALL
  // ==========================

  Future<void> acceptCall() async {
    try {
      await _channel.invokeMethod('acceptCall');
      _logger.i("Call answered");
    } catch (e) {
      _logger.e("Error answering call: $e");
    }
  }

  // ==========================
  // REJECT CALL
  // ==========================

  Future<void> rejectCall() async {
    try {
      await _channel.invokeMethod('rejectCall');
      _logger.i("Call rejected");
    } catch (e) {
      _logger.e("Error rejecting call: $e");
    }
  }
}

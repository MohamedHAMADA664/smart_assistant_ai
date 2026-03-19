import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class CallControlService {
  CallControlService({
    Logger? logger,
  }) : _logger = logger ?? Logger();

  static const MethodChannel _channel =
      MethodChannel('smart_assistant/call_control');

  final Logger _logger;

  // ==========================
  // ANSWER CALL
  // ==========================

  Future<bool> acceptCall() async {
    return _invokeCallAction(
      method: 'acceptCall',
      successMessage: 'Call answered',
      errorMessage: 'Error answering call',
    );
  }

  // ==========================
  // REJECT CALL
  // ==========================

  Future<bool> rejectCall() async {
    return _invokeCallAction(
      method: 'rejectCall',
      successMessage: 'Call rejected',
      errorMessage: 'Error rejecting call',
    );
  }

  // ==========================
  // INTERNAL HELPER
  // ==========================

  Future<bool> _invokeCallAction({
    required String method,
    required String successMessage,
    required String errorMessage,
  }) async {
    try {
      await _channel.invokeMethod(method);
      _logger.i(successMessage);
      return true;
    } on PlatformException catch (e, stackTrace) {
      _logger.e(
        errorMessage,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } catch (e, stackTrace) {
      _logger.e(
        errorMessage,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

import 'dart:async';

import 'package:phone_state/phone_state.dart';

import '../core/system_controller.dart';
import 'contact_call_service.dart';
import 'voice_response_service.dart';

class CallListenerService {
  CallListenerService({
    ContactCallService? contactCallService,
    VoiceResponseService? voiceResponseService,
    SystemController? systemController,
  })  : _contacts = contactCallService ?? ContactCallService(),
        _voice = voiceResponseService ?? VoiceResponseService(),
        _systemController = systemController ?? SystemController();

  final ContactCallService _contacts;
  final VoiceResponseService _voice;
  final SystemController _systemController;

  StreamSubscription<PhoneState>? _phoneStateSubscription;
  bool _started = false;

  bool get isStarted => _started;

  // ================================
  // START LISTENING
  // ================================

  Future<void> startListening() async {
    if (_started) {
      return;
    }

    await _contacts.loadContacts();

    _phoneStateSubscription = PhoneState.stream.listen(
      (PhoneState state) async {
        if (state.status != PhoneStateStatus.CALL_INCOMING) {
          return;
        }

        final rawNumber = state.number?.trim();
        if (rawNumber == null || rawNumber.isEmpty) {
          await _handleIncomingCall('رقم غير معروف');
          return;
        }

        await _handleIncomingCall(rawNumber);
      },
      onError: (_) {
        // Ignore stream errors silently for now.
      },
    );

    _started = true;
  }

  // ================================
  // STOP LISTENING
  // ================================

  Future<void> stopListening() async {
    await _phoneStateSubscription?.cancel();
    _phoneStateSubscription = null;
    _started = false;
  }

  // ================================
  // DISPOSE
  // ================================

  Future<void> dispose() async {
    await stopListening();
  }

  // ================================
  // HANDLE INCOMING CALL
  // ================================

  Future<void> _handleIncomingCall(String number) async {
    final callerName = await _findContactName(number);
    final displayName = callerName.isNotEmpty ? callerName : 'رقم غير مسجل';

    await _voice.speak('مكالمة من $displayName، قل رد أو ارفض');
    await _systemController.onIncomingCall(number);
  }

  // ================================
  // FIND CONTACT NAME
  // ================================

  Future<String> _findContactName(String number) async {
    final cleanedIncomingNumber = _cleanNumber(number);

    for (final contact in _contacts.contacts) {
      for (final phone in contact.phones) {
        final cleanedContactNumber = _cleanNumber(phone.number);

        if (cleanedContactNumber.isEmpty || cleanedIncomingNumber.isEmpty) {
          continue;
        }

        if (cleanedContactNumber.endsWith(cleanedIncomingNumber) ||
            cleanedIncomingNumber.endsWith(cleanedContactNumber)) {
          return contact.displayName;
        }
      }
    }

    return '';
  }

  // ================================
  // CLEAN PHONE NUMBER
  // ================================

  String _cleanNumber(String number) {
    return number.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

import 'package:phone_state/phone_state.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'contact_call_service.dart';

import 'call_control_service.dart';
import 'voice_listener_service.dart';

class CallListenerService {
  final FlutterTts _tts = FlutterTts();

  final ContactCallService _contacts = ContactCallService();
  final CallControlService _callControl = CallControlService();
  final VoiceListenerService _voiceListener = VoiceListenerService();

  bool _listeningForResponse = false;

  // ================================
  // START LISTENING
  // ================================

  Future<void> startListening() async {
    await _contacts.loadContacts();

    PhoneState.stream.listen((PhoneState state) async {
      if (state.status == PhoneStateStatus.CALL_INCOMING) {
        String? number = state.number;

        if (number != null && number.isNotEmpty) {
          await _announceCaller(number);
        }
      }
    });
  }

  // ================================
  // ANNOUNCE CALLER
  // ================================

  Future<void> _announceCaller(String number) async {
    String callerName = await _findContactName(number);

    if (callerName.isNotEmpty) {
      await _speak("مكالمة من $callerName هل تريد الرد أم الرفض");
    } else {
      await _speak("مكالمة من رقم غير مسجل هل تريد الرد أم الرفض");
    }

    await _listenForVoiceResponse();
  }

  // ================================
  // FIND CONTACT NAME
  // ================================

  Future<String> _findContactName(String number) async {
    number = _cleanNumber(number);

    for (var contact in _contacts.contacts) {
      for (var phone in contact.phones) {
        String contactNumber = _cleanNumber(phone.number);

        if (contactNumber.contains(number)) {
          return contact.displayName;
        }
      }
    }

    return "";
  }

  // ================================
  // CLEAN PHONE NUMBER
  // ================================

  String _cleanNumber(String number) {
    return number.replaceAll(" ", "").replaceAll("-", "").replaceAll("+", "");
  }

  // ================================
  // LISTEN FOR VOICE RESPONSE
  // ================================

  Future<void> _listenForVoiceResponse() async {
    if (_listeningForResponse) return;

    _listeningForResponse = true;

    await _voiceListener.initialize();

    await _voiceListener.startListening();
  }

  // ================================
  // HANDLE COMMAND
  // ================================

  Future<void> handleVoiceCommand(String text) async {
    if (!_listeningForResponse) return;

    String command = text.toLowerCase();

    if (command.contains("رد") || command.contains("answer")) {
      await _callControl.acceptCall();

      _stopVoiceResponse();
    }

    if (command.contains("ارفض") ||
        command.contains("اقفل") ||
        command.contains("reject")) {
      await _callControl.rejectCall();

      _stopVoiceResponse();
    }
  }

  // ================================
  // STOP LISTENING
  // ================================

  void _stopVoiceResponse() {
    _listeningForResponse = false;

    _voiceListener.stopListening();
  }

  // ================================
  // SPEAK
  // ================================

  Future<void> _speak(String text) async {
    await _tts.setLanguage("ar");

    await _tts.setSpeechRate(0.5);

    await _tts.speak(text);
  }
}

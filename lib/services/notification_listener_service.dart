import 'dart:async';

import 'package:notification_listener_service/notification_listener_service.dart';

import 'voice_response_service.dart';

class NotificationListenerServiceAI {
  NotificationListenerServiceAI({
    VoiceResponseService? voiceResponseService,
  }) : _voice = voiceResponseService ?? VoiceResponseService();

  final VoiceResponseService _voice;

  StreamSubscription<dynamic>? _notificationSubscription;
  String? _lastNotificationFingerprint;
  bool _started = false;

  bool get isStarted => _started;

  static const Map<String, String> _supportedApps = {
    'com.whatsapp': 'واتساب',
    'com.facebook.orca': 'ماسنجر',
    'org.telegram.messenger': 'تيليجرام',
  };

  // ==========================
  // START LISTENING
  // ==========================

  Future<void> startListening() async {
    if (_started) {
      return;
    }

    _notificationSubscription =
        NotificationListenerService.notificationsStream.listen(
      (event) async {
        try {
          final packageName = event.packageName?.trim();
          final title = event.title?.trim();
          final content = event.content?.trim();

          if (packageName == null || packageName.isEmpty) {
            return;
          }

          final appName = _supportedApps[packageName];
          if (appName == null) {
            return;
          }

          if (title == null || title.isEmpty) {
            return;
          }

          if (content == null || content.isEmpty) {
            return;
          }

          final fingerprint = _buildNotificationFingerprint(
            packageName: packageName,
            title: title,
            content: content,
          );

          if (_lastNotificationFingerprint == fingerprint) {
            return;
          }

          _lastNotificationFingerprint = fingerprint;

          await _announceMessage(
            appName: appName,
            sender: title,
            message: content,
          );
        } catch (_) {
          // Ignore notification parsing errors silently for now.
        }
      },
      onError: (_) {
        // Ignore stream errors silently for now.
      },
    );

    _started = true;
  }

  // ==========================
  // STOP LISTENING
  // ==========================

  Future<void> stopListening() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _started = false;
  }

  // ==========================
  // DISPOSE
  // ==========================

  Future<void> dispose() async {
    await stopListening();
  }

  // ==========================
  // ANNOUNCE MESSAGE
  // ==========================

  Future<void> _announceMessage({
    required String appName,
    required String sender,
    required String message,
  }) async {
    final speech = 'لديك رسالة جديدة من $sender على $appName';
    await _voice.speak(speech);
  }

  // ==========================
  // HELPERS
  // ==========================

  String _buildNotificationFingerprint({
    required String packageName,
    required String title,
    required String content,
  }) {
    return '$packageName|$title|$content';
  }
}

import 'package:url_launcher/url_launcher.dart';

import '../models/app_task_model.dart';

class MessagingTaskService {
  static const String whatsappPackageName = 'com.whatsapp';
  static const String whatsappBusinessPackageName = 'com.whatsapp.w4b';
  static const String telegramPackageName = 'org.telegram.messenger';
  static const String smsPackageName = 'sms';

  // ================================
  // PREPARE MESSAGE TASK
  // ================================

  Future<MessagingTaskResult> prepareMessage(AppTaskModel task) async {
    if (task.taskType != AppTaskType.prepareMessage &&
        task.taskType != AppTaskType.openChat) {
      return const MessagingTaskResult(
        status: MessagingTaskStatus.unsupportedTask,
        message: 'نوع المهمة غير مدعوم لخدمة الرسائل',
      );
    }

    final packageName = task.targetPackageName?.trim();
    final contactName = task.contactName?.trim();
    final messageText = task.messageText?.trim();

    if (packageName == null || packageName.isEmpty) {
      return const MessagingTaskResult(
        status: MessagingTaskStatus.missingTargetApp,
        message: 'لم يتم تحديد تطبيق الرسائل',
      );
    }

    if (contactName == null || contactName.isEmpty) {
      return const MessagingTaskResult(
        status: MessagingTaskStatus.missingContact,
        message: 'لم يتم تحديد جهة الاتصال',
      );
    }

    switch (packageName) {
      case whatsappPackageName:
      case whatsappBusinessPackageName:
        return _prepareWhatsAppMessage(
          packageName: packageName,
          contactName: contactName,
          messageText: messageText,
          openChatOnly: task.taskType == AppTaskType.openChat,
        );

      case telegramPackageName:
        return _prepareTelegramMessage(
          contactName: contactName,
          messageText: messageText,
          openChatOnly: task.taskType == AppTaskType.openChat,
        );

      case smsPackageName:
        return _prepareSmsMessage(
          contactName: contactName,
          messageText: messageText,
          openChatOnly: task.taskType == AppTaskType.openChat,
        );

      default:
        return MessagingTaskResult(
          status: MessagingTaskStatus.unsupportedApp,
          message: 'تطبيق الرسائل غير مدعوم حاليًا',
          targetPackageName: packageName,
          contactName: contactName,
        );
    }
  }

  // ================================
  // WHATSAPP
  // ================================

  Future<MessagingTaskResult> _prepareWhatsAppMessage({
    required String packageName,
    required String contactName,
    required String? messageText,
    required bool openChatOnly,
  }) async {
    final normalizedContact = _normalizeText(contactName);
    final normalizedMessage = _normalizeText(messageText);

    final text =
        openChatOnly ? 'فتح محادثة $normalizedContact' : normalizedMessage;

    if (!openChatOnly && text.isEmpty) {
      return MessagingTaskResult(
        status: MessagingTaskStatus.missingMessage,
        message: 'لم يتم تحديد نص الرسالة',
        targetPackageName: packageName,
        contactName: normalizedContact,
      );
    }

    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(text)}',
    );

    final launched = await _launchUri(uri);

    if (!launched) {
      return MessagingTaskResult(
        status: MessagingTaskStatus.launchFailed,
        message: 'تعذر فتح واتساب لتجهيز الرسالة',
        targetPackageName: packageName,
        contactName: normalizedContact,
      );
    }

    return MessagingTaskResult(
      status: MessagingTaskStatus.prepared,
      message: openChatOnly
          ? 'تم فتح واتساب لتجهيز المحادثة'
          : 'تم فتح واتساب وتجهيز الرسالة',
      targetPackageName: packageName,
      contactName: normalizedContact,
      preparedMessage: openChatOnly ? null : normalizedMessage,
    );
  }

  // ================================
  // TELEGRAM
  // ================================

  Future<MessagingTaskResult> _prepareTelegramMessage({
    required String contactName,
    required String? messageText,
    required bool openChatOnly,
  }) async {
    final normalizedContact = _normalizeText(contactName);
    final normalizedMessage = _normalizeText(messageText);

    final uri = openChatOnly
        ? Uri.parse(
            'https://t.me/',
          )
        : Uri.parse(
            'https://t.me/share/url?text=${Uri.encodeComponent(normalizedMessage)}',
          );

    if (!openChatOnly && normalizedMessage.isEmpty) {
      return MessagingTaskResult(
        status: MessagingTaskStatus.missingMessage,
        message: 'لم يتم تحديد نص الرسالة',
        targetPackageName: telegramPackageName,
        contactName: normalizedContact,
      );
    }

    final launched = await _launchUri(uri);

    if (!launched) {
      return MessagingTaskResult(
        status: MessagingTaskStatus.launchFailed,
        message: 'تعذر فتح تيليجرام لتجهيز الرسالة',
        targetPackageName: telegramPackageName,
        contactName: normalizedContact,
      );
    }

    return MessagingTaskResult(
      status: MessagingTaskStatus.prepared,
      message:
          openChatOnly ? 'تم فتح تيليجرام' : 'تم فتح تيليجرام وتجهيز الرسالة',
      targetPackageName: telegramPackageName,
      contactName: normalizedContact,
      preparedMessage: openChatOnly ? null : normalizedMessage,
    );
  }

  // ================================
  // SMS
  // ================================

  Future<MessagingTaskResult> _prepareSmsMessage({
    required String contactName,
    required String? messageText,
    required bool openChatOnly,
  }) async {
    final normalizedContact = _normalizeText(contactName);
    final normalizedMessage = _normalizeText(messageText);

    final body = openChatOnly ? '' : normalizedMessage;

    if (!openChatOnly && body.isEmpty) {
      return MessagingTaskResult(
        status: MessagingTaskStatus.missingMessage,
        message: 'لم يتم تحديد نص الرسالة',
        targetPackageName: smsPackageName,
        contactName: normalizedContact,
      );
    }

    final uri = Uri.parse(
      'sms:?body=${Uri.encodeComponent(body)}',
    );

    final launched = await _launchUri(uri);

    if (!launched) {
      return MessagingTaskResult(
        status: MessagingTaskStatus.launchFailed,
        message: 'تعذر فتح تطبيق الرسائل',
        targetPackageName: smsPackageName,
        contactName: normalizedContact,
      );
    }

    return MessagingTaskResult(
      status: MessagingTaskStatus.prepared,
      message: openChatOnly
          ? 'تم فتح تطبيق الرسائل'
          : 'تم فتح تطبيق الرسائل وتجهيز النص',
      targetPackageName: smsPackageName,
      contactName: normalizedContact,
      preparedMessage: openChatOnly ? null : normalizedMessage,
    );
  }

  // ================================
  // HELPERS
  // ================================

  Future<bool> _launchUri(Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) {
        return false;
      }

      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  String _normalizeText(String? text) {
    return (text ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class MessagingTaskResult {
  const MessagingTaskResult({
    required this.status,
    required this.message,
    this.targetPackageName,
    this.contactName,
    this.preparedMessage,
  });

  final MessagingTaskStatus status;
  final String message;
  final String? targetPackageName;
  final String? contactName;
  final String? preparedMessage;

  bool get isSuccess => status == MessagingTaskStatus.prepared;
}

enum MessagingTaskStatus {
  prepared,
  missingTargetApp,
  missingContact,
  missingMessage,
  unsupportedTask,
  unsupportedApp,
  launchFailed,
}

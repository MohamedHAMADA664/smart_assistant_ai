import '../models/app_task_model.dart';
import 'app_action_registry_service.dart';
import 'app_control_service.dart';

class AppTaskPlannerService {
  AppTaskPlannerService({
    AppControlService? appControlService,
    AppActionRegistryService? appActionRegistryService,
  })  : _appControlService = appControlService ?? AppControlService(),
        _appActionRegistryService =
            appActionRegistryService ?? AppActionRegistryService();

  final AppControlService _appControlService;
  final AppActionRegistryService _appActionRegistryService;

  Future<AppTaskPlanResult> planFromText(String rawText) async {
    final normalizedText = _normalize(rawText);

    if (normalizedText.isEmpty) {
      return const AppTaskPlanResult(
        status: AppTaskPlanStatus.invalidInput,
        reason: 'النص المدخل فارغ',
      );
    }

    final taskType = _detectTaskType(normalizedText);
    final targetAppName = _extractTargetAppName(normalizedText, taskType);
    final contactName = _extractContactName(normalizedText, taskType);
    final messageText = _extractMessageText(normalizedText, taskType);
    final searchQuery = _extractSearchQuery(normalizedText, taskType);
    final storeAppName = _extractStoreAppName(normalizedText, taskType);
    final serverName = _extractServerName(normalizedText, taskType);

    final needsMoreDetails = _needsMoreDetails(
      taskType: taskType,
      targetAppName: targetAppName,
      contactName: contactName,
      messageText: messageText,
      searchQuery: searchQuery,
      storeAppName: storeAppName,
    );

    if (needsMoreDetails != null) {
      return AppTaskPlanResult(
        status: AppTaskPlanStatus.needsMoreDetails,
        reason: needsMoreDetails,
        originalText: rawText,
        suggestedAppName: targetAppName,
      );
    }

    if (_taskNeedsApp(taskType) &&
        (targetAppName == null || targetAppName.trim().isEmpty)) {
      return const AppTaskPlanResult(
        status: AppTaskPlanStatus.missingTargetApp,
        reason: 'لم يتم تحديد التطبيق المستهدف',
      );
    }

    ResolvedApp? resolvedApp;
    if (targetAppName != null && targetAppName.trim().isNotEmpty) {
      resolvedApp = await _appControlService.resolveApp(targetAppName);
    }

    if (_taskNeedsApp(taskType) && resolvedApp == null) {
      return AppTaskPlanResult(
        status: AppTaskPlanStatus.appNotFound,
        reason: 'لم أتمكن من العثور على التطبيق المطلوب',
        originalText: rawText,
        suggestedAppName: targetAppName,
      );
    }

    final resolvedTask = AppTaskModel(
      taskType: taskType,
      targetAppName: resolvedApp?.displayName ?? targetAppName,
      targetPackageName: resolvedApp?.packageName,
      contactName: contactName,
      messageText: messageText,
      searchQuery: searchQuery,
      storeAppName: storeAppName,
      serverName: serverName,
    );

    if (resolvedApp == null) {
      return AppTaskPlanResult(
        status: taskType == AppTaskType.unknown
            ? AppTaskPlanStatus.unknownTask
            : AppTaskPlanStatus.ready,
        originalText: rawText,
        task: resolvedTask,
        reason: taskType == AppTaskType.unknown ? 'لم يتم فهم المهمة' : null,
      );
    }

    final supportsTask = _appActionRegistryService.supportsTask(
      packageName: resolvedApp.packageName,
      taskType: taskType,
    );

    if (!supportsTask) {
      return AppTaskPlanResult(
        status: AppTaskPlanStatus.unsupportedForApp,
        originalText: rawText,
        task: resolvedTask,
        resolvedApp: resolvedApp,
        reason: 'التطبيق معروف لكن المهمة غير مدعومة حاليًا',
      );
    }

    final requiresConfirmation =
        _appActionRegistryService.taskRequiresConfirmation(
      packageName: resolvedApp.packageName,
      taskType: taskType,
    );

    final requiresInternet = _appActionRegistryService.taskRequiresInternet(
      packageName: resolvedApp.packageName,
      taskType: taskType,
    );

    final requiresAutomation = _appActionRegistryService.taskRequiresAutomation(
      packageName: resolvedApp.packageName,
      taskType: taskType,
    );

    final finalTask = resolvedTask.copyWith(
      requiresConfirmation: requiresConfirmation,
      requiresInternet: requiresInternet,
      requiresAutomation: requiresAutomation,
    );

    return AppTaskPlanResult(
      status: AppTaskPlanStatus.ready,
      originalText: rawText,
      task: finalTask,
      resolvedApp: resolvedApp,
    );
  }

  AppTaskType _detectTaskType(String text) {
    if (_containsAny(text, const ['نزّل', 'نزل', 'ثبت', 'حمّل', 'تحميل'])) {
      return AppTaskType.installApp;
    }

    if (_containsAny(text, const ['المتجر', 'بلاي ستور', 'play store'])) {
      if (_containsAny(text, const ['ابحث', 'دور', 'search'])) {
        return AppTaskType.searchStore;
      }

      return AppTaskType.openStoreListing;
    }

    if (_containsAny(text, const ['ابعت', 'ارسل', 'أرسل', 'بعت'])) {
      if (_containsAny(
        text,
        const ['رسالة', 'واتساب', 'تليجرام', 'telegram', 'whatsapp'],
      )) {
        return AppTaskType.prepareMessage;
      }
    }

    if (_containsAny(text, const ['افتح شات', 'افتح المحادثة', 'افتح دردشة'])) {
      return AppTaskType.openChat;
    }

    if (_containsAny(text, const ['ابحث', 'دور', 'search'])) {
      return AppTaskType.searchInApp;
    }

    if (_containsAny(text, const ['اتصل', 'وصل', 'connect'])) {
      if (_containsAny(text, const ['vpn', 'في بي ان', 'سيرفر', 'server'])) {
        return AppTaskType.connectVpn;
      }
    }

    if (_containsAny(text, const ['افصل', 'اقفل vpn', 'disconnect'])) {
      if (_containsAny(text, const ['vpn', 'في بي ان'])) {
        return AppTaskType.disconnectVpn;
      }
    }

    if (_containsAny(text, const ['افتح', 'شغل', 'ابدأ', 'run', 'open'])) {
      return AppTaskType.openApp;
    }

    return AppTaskType.unknown;
  }

  String? _extractTargetAppName(String text, AppTaskType taskType) {
    switch (taskType) {
      case AppTaskType.openApp:
        return _cleanExtractedValue(
          _extractAfterFirstKeyword(
            text,
            const ['افتح', 'شغل', 'ابدأ', 'open', 'run'],
          ),
        );

      case AppTaskType.openChat:
      case AppTaskType.prepareMessage:
        if (_containsAny(
          text,
          const ['واتساب بيزنس', 'واتساب بزنس', 'whatsapp business'],
        )) {
          return 'واتساب بيزنس';
        }

        if (_containsAny(text, const ['واتساب', 'whatsapp'])) {
          return 'واتساب';
        }

        if (_containsAny(text, const ['تليجرام', 'telegram'])) {
          return 'تليجرام';
        }

        return null;

      case AppTaskType.searchInApp:
        if (_containsAny(text, const ['يوتيوب', 'youtube'])) {
          return 'يوتيوب';
        }

        if (_containsAny(text, const ['خرائط', 'maps', 'google maps'])) {
          return 'خرائط';
        }

        if (_containsAny(text, const ['جوجل', 'google', 'كروم', 'chrome'])) {
          return 'جوجل';
        }

        return _cleanExtractedValue(
          _extractAfterFirstKeyword(
            text,
            const ['ابحث في', 'دور في', 'search in'],
          ),
        );

      case AppTaskType.searchStore:
      case AppTaskType.openStoreListing:
      case AppTaskType.installApp:
        return 'المتجر';

      case AppTaskType.connectVpn:
      case AppTaskType.disconnectVpn:
        return _extractVpnAppName(text);

      case AppTaskType.sendMessage:
      case AppTaskType.openSettingsInApp:
      case AppTaskType.unknown:
        return null;
    }
  }

  String? _extractContactName(String text, AppTaskType taskType) {
    if (taskType != AppTaskType.prepareMessage &&
        taskType != AppTaskType.openChat) {
      return null;
    }

    for (final marker in const ['ل', 'الى', 'إلى', 'to']) {
      final extracted = _findFirstMarker(text, [marker]);
      if (extracted == null || extracted.isEmpty) {
        continue;
      }

      var result = extracted.trim();

      for (final stopWord in const [
        'وقوله',
        'وقل له',
        'قول له',
        'قل له',
        'قول',
        'رسالة',
        'message',
        'على واتساب',
        'في واتساب',
        'على تليجرام',
        'في تليجرام',
        'واتساب',
        'تليجرام',
      ]) {
        final index = result.indexOf(stopWord);
        if (index > 0) {
          result = result.substring(0, index).trim();
        }
      }

      result = _cleanExtractedValue(result) ?? '';

      if (result.isNotEmpty) {
        return result;
      }
    }

    return null;
  }

  String? _extractMessageText(String text, AppTaskType taskType) {
    if (taskType != AppTaskType.prepareMessage) {
      return null;
    }

    for (final marker in const [
      'وقوله',
      'وقل له',
      'قول له',
      'قل له',
      'message',
      'محتوى الرسالة',
      'نص الرسالة',
    ]) {
      final index = text.indexOf(marker);
      if (index >= 0) {
        final message = text.substring(index + marker.length).trim();
        final cleaned = _cleanExtractedValue(message);
        if (cleaned != null && cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    }

    return null;
  }

  String? _extractSearchQuery(String text, AppTaskType taskType) {
    if (taskType != AppTaskType.searchInApp &&
        taskType != AppTaskType.searchStore) {
      return null;
    }

    final query = _extractAfterFirstKeyword(
      text,
      const ['ابحث عن', 'ابحث', 'دور على', 'دور', 'search for', 'search'],
    );

    if (query == null || query.trim().isEmpty) {
      return null;
    }

    var cleaned = query.trim();

    for (final suffix in const [
      'في يوتيوب',
      'في اليوتيوب',
      'على يوتيوب',
      'على اليوتيوب',
      'في جوجل',
      'على جوجل',
      'في كروم',
      'على كروم',
      'في خرائط',
      'على خرائط',
      'في المتجر',
      'على المتجر',
      'في بلاي ستور',
      'على بلاي ستور',
    ]) {
      if (cleaned.endsWith(suffix)) {
        cleaned = cleaned.substring(0, cleaned.length - suffix.length).trim();
      }
    }

    final result = _cleanExtractedValue(cleaned);
    return result == null || result.isEmpty ? null : result;
  }

  String? _extractStoreAppName(String text, AppTaskType taskType) {
    if (taskType != AppTaskType.openStoreListing &&
        taskType != AppTaskType.installApp &&
        taskType != AppTaskType.searchStore) {
      return null;
    }

    for (final marker in const [
      'برنامج',
      'تطبيق',
      'ابلكيشن',
      'application',
      'app',
    ]) {
      final index = text.indexOf(marker);
      if (index >= 0) {
        final appName = text.substring(index + marker.length).trim();
        final cleaned = _cleanStoreName(appName);
        if (cleaned != null && cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    }

    final fallback = _extractAfterFirstKeyword(
      text,
      const [
        'نزّل',
        'نزل',
        'ثبت',
        'حمّل',
        'تحميل',
        'افتح المتجر على',
        'افتح المتجر',
        'ابحث في المتجر عن',
        'ابحث في المتجر',
      ],
    );

    final cleaned = _cleanStoreName(fallback);
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  String? _extractServerName(String text, AppTaskType taskType) {
    if (taskType != AppTaskType.connectVpn) {
      return null;
    }

    for (final marker in const ['سيرفر', 'server']) {
      final index = text.indexOf(marker);
      if (index >= 0) {
        final value = text.substring(index + marker.length).trim();
        final cleaned = _cleanExtractedValue(value);
        if (cleaned != null && cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    }

    return null;
  }

  String? _extractVpnAppName(String text) {
    if (_containsAny(text, const ['vpn master', 'في بي ان ماستر'])) {
      return 'vpn master';
    }

    if (_containsAny(text, const ['super vpn', 'سوبر vpn', 'سوبر في بي ان'])) {
      return 'super vpn';
    }

    if (_containsAny(text, const ['vpn'])) {
      final extracted = _extractAfterFirstKeyword(
        text,
        const ['افتح', 'شغل', 'connect', 'اتصل'],
      );

      final cleaned = _cleanExtractedValue(extracted);
      return cleaned == null || cleaned.isEmpty ? 'vpn' : cleaned;
    }

    if (_containsAny(text, const ['في بي ان'])) {
      return 'vpn';
    }

    return null;
  }

  String? _needsMoreDetails({
    required AppTaskType taskType,
    required String? targetAppName,
    required String? contactName,
    required String? messageText,
    required String? searchQuery,
    required String? storeAppName,
  }) {
    switch (taskType) {
      case AppTaskType.prepareMessage:
        if (contactName == null || contactName.trim().isEmpty) {
          return 'اذكر اسم جهة الاتصال التي تريد المراسلة إليها';
        }

        if (messageText == null || messageText.trim().isEmpty) {
          return 'اذكر نص الرسالة المطلوب إرساله';
        }

        return null;

      case AppTaskType.openChat:
        if (contactName == null || contactName.trim().isEmpty) {
          return 'اذكر اسم جهة الاتصال التي تريد فتح المحادثة معها';
        }

        return null;

      case AppTaskType.searchInApp:
        if (searchQuery == null || searchQuery.trim().isEmpty) {
          return 'اذكر ما الذي تريد البحث عنه';
        }

        return null;

      case AppTaskType.searchStore:
      case AppTaskType.openStoreListing:
      case AppTaskType.installApp:
        if (storeAppName == null || storeAppName.trim().isEmpty) {
          return 'اذكر اسم التطبيق المطلوب في المتجر';
        }

        return null;

      case AppTaskType.openApp:
      case AppTaskType.connectVpn:
      case AppTaskType.disconnectVpn:
        if (_taskNeedsApp(taskType) &&
            (targetAppName == null || targetAppName.trim().isEmpty)) {
          return 'اذكر اسم التطبيق المطلوب';
        }

        return null;

      case AppTaskType.sendMessage:
      case AppTaskType.openSettingsInApp:
      case AppTaskType.unknown:
        return null;
    }
  }

  bool _taskNeedsApp(AppTaskType taskType) {
    switch (taskType) {
      case AppTaskType.openApp:
      case AppTaskType.openChat:
      case AppTaskType.prepareMessage:
      case AppTaskType.searchInApp:
      case AppTaskType.openStoreListing:
      case AppTaskType.searchStore:
      case AppTaskType.installApp:
      case AppTaskType.connectVpn:
      case AppTaskType.disconnectVpn:
      case AppTaskType.openSettingsInApp:
        return true;

      case AppTaskType.sendMessage:
      case AppTaskType.unknown:
        return false;
    }
  }

  bool _containsAny(String text, List<String> words) {
    for (final word in words) {
      if (text.contains(word)) {
        return true;
      }
    }

    return false;
  }

  String? _extractAfterFirstKeyword(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final index = text.indexOf(keyword);
      if (index >= 0) {
        final result = text.substring(index + keyword.length).trim();
        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return null;
  }

  String? _findFirstMarker(String text, List<String> markers) {
    for (final marker in markers) {
      final directIndex = text.indexOf('$marker ');
      if (directIndex >= 0) {
        final result = text.substring(directIndex + marker.length).trim();
        if (result.isNotEmpty) {
          return result;
        }
      }

      final spacedIndex = text.indexOf(' $marker ');
      if (spacedIndex >= 0) {
        final result = text.substring(spacedIndex + marker.length + 1).trim();
        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return null;
  }

  String? _cleanExtractedValue(String? value) {
    if (value == null) {
      return null;
    }

    var result = value.trim();

    if (result.isEmpty) {
      return null;
    }

    for (final separator in const [
      ' وابعت',
      ' و ابعت',
      ' وارسل',
      ' و ارسل',
      ' وابحث',
      ' و ابحث',
      ' ودور',
      ' و دور',
      ' وقول',
      ' و قول',
      ' وقل',
      ' و قل',
      ' ثم',
      ' بعدين',
      ' وبعدها',
      ' وبعد كده',
    ]) {
      final index = result.indexOf(separator);
      if (index > 0) {
        result = result.substring(0, index).trim();
      }
    }

    result = result
        .replaceAll(RegExp(r'^(في|على|من)\s+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return result.isEmpty ? null : result;
  }

  String? _cleanStoreName(String? value) {
    final cleaned = _cleanExtractedValue(value);
    if (cleaned == null) {
      return null;
    }

    var result = cleaned;

    for (final suffix in const [
      'من المتجر',
      'في المتجر',
      'على المتجر',
      'من بلاي ستور',
      'في بلاي ستور',
      'على بلاي ستور',
      'play store',
    ]) {
      if (result.endsWith(suffix)) {
        result = result.substring(0, result.length - suffix.length).trim();
      }
    }

    return result.isEmpty ? null : result;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[،,.!?؟]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class AppTaskPlanResult {
  const AppTaskPlanResult({
    required this.status,
    this.originalText,
    this.task,
    this.resolvedApp,
    this.reason,
    this.suggestedAppName,
  });

  final AppTaskPlanStatus status;
  final String? originalText;
  final AppTaskModel? task;
  final ResolvedApp? resolvedApp;
  final String? reason;
  final String? suggestedAppName;

  bool get isReady => status == AppTaskPlanStatus.ready;
  bool get hasError => status != AppTaskPlanStatus.ready;
}

enum AppTaskPlanStatus {
  ready,
  invalidInput,
  unknownTask,
  missingTargetApp,
  appNotFound,
  unsupportedForApp,
  needsMoreDetails,
}

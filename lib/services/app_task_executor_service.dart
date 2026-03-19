import '../models/app_task_model.dart';
import 'app_control_service.dart';
import 'app_task_planner_service.dart';
import 'messaging_task_service.dart';
import 'music_service.dart';
import 'play_store_service.dart';
import 'system_control_service.dart';

class AppTaskExecutorService {
  AppTaskExecutorService({
    AppControlService? appControlService,
    PlayStoreService? playStoreService,
    MessagingTaskService? messagingTaskService,
    MusicService? musicService,
    SystemControlService? systemControlService,
  })  : _appControlService = appControlService ?? AppControlService(),
        _playStoreService = playStoreService ?? PlayStoreService(),
        _messagingTaskService = messagingTaskService ?? MessagingTaskService(),
        _musicService = musicService ?? MusicService(),
        _systemControlService = systemControlService ?? SystemControlService();

  final AppControlService _appControlService;
  final PlayStoreService _playStoreService;
  final MessagingTaskService _messagingTaskService;
  final MusicService _musicService;
  final SystemControlService _systemControlService;

  // ================================
  // EXECUTE PLAN
  // ================================

  Future<AppTaskExecutionResult> executePlan(
    AppTaskPlanResult planResult,
  ) async {
    if (!planResult.isReady || planResult.task == null) {
      return AppTaskExecutionResult(
        status: AppTaskExecutionStatus.invalidPlan,
        message: planResult.reason ?? 'الخطة غير جاهزة للتنفيذ',
      );
    }

    final task = planResult.task!;

    switch (task.taskType) {
      case AppTaskType.openApp:
        return _executeOpenApp(task);

      case AppTaskType.openChat:
      case AppTaskType.prepareMessage:
        return _executeMessagingTask(task);

      case AppTaskType.searchInApp:
        return _executeSearchInApp(task);

      case AppTaskType.openStoreListing:
      case AppTaskType.installApp:
        return _executeOpenStoreListing(task);

      case AppTaskType.searchStore:
        return _executeSearchStore(task);

      case AppTaskType.connectVpn:
      case AppTaskType.disconnectVpn:
        return _executeVpnTask(task);

      case AppTaskType.sendMessage:
      case AppTaskType.openSettingsInApp:
      case AppTaskType.unknown:
        return const AppTaskExecutionResult(
          status: AppTaskExecutionStatus.unsupported,
          message: 'هذه المهمة غير مدعومة في مرحلة التنفيذ الحالية',
        );
    }
  }

  // ================================
  // OPEN APP
  // ================================

  Future<AppTaskExecutionResult> _executeOpenApp(AppTaskModel task) async {
    final appName = task.targetAppName?.trim();

    if (appName == null || appName.isEmpty) {
      return const AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'لم يتم تحديد التطبيق المطلوب فتحه',
      );
    }

    final opened = await _tryOpenAppWithFallbacks(appName);

    if (!opened) {
      return AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'تعذر فتح التطبيق: $appName',
        task: task,
      );
    }

    return AppTaskExecutionResult(
      status: AppTaskExecutionStatus.success,
      message: 'تم فتح التطبيق: $appName',
      task: task,
    );
  }

  // ================================
  // MESSAGING
  // ================================

  Future<AppTaskExecutionResult> _executeMessagingTask(
    AppTaskModel task,
  ) async {
    final result = await _messagingTaskService.prepareMessage(task);

    if (!result.isSuccess) {
      return AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: result.message,
        task: task,
      );
    }

    return AppTaskExecutionResult(
      status: AppTaskExecutionStatus.success,
      message: result.message,
      task: task,
    );
  }

  // ================================
  // SEARCH IN APP
  // ================================

  Future<AppTaskExecutionResult> _executeSearchInApp(
    AppTaskModel task,
  ) async {
    final packageName = task.targetPackageName?.trim();
    final query = task.searchQuery?.trim();

    if (packageName == null || packageName.isEmpty) {
      return const AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'لم يتم تحديد التطبيق المستهدف للبحث',
      );
    }

    if (query == null || query.isEmpty) {
      return const AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'لم يتم تحديد نص البحث',
      );
    }

    switch (packageName) {
      case 'com.google.android.youtube':
      case 'com.google.android.apps.youtube.music':
        final launched = await _musicService.playYoutube(query);
        return AppTaskExecutionResult(
          status: launched
              ? AppTaskExecutionStatus.success
              : AppTaskExecutionStatus.failed,
          message: launched
              ? 'تم فتح التطبيق وتجهيز البحث: $query'
              : 'تعذر تنفيذ البحث في يوتيوب',
          task: task,
        );

      case 'com.google.android.apps.maps':
        final launched = await _systemControlService.webSearch(
          'خرائط $query',
        );
        return AppTaskExecutionResult(
          status: launched
              ? AppTaskExecutionStatus.partialSuccess
              : AppTaskExecutionStatus.failed,
          message: launched
              ? 'تم فتح بحث مرتبط بالخرائط: $query'
              : 'تعذر تنفيذ البحث المرتبط بالخرائط',
          task: task,
        );

      case 'com.android.chrome':
      case 'com.google.android.googlequicksearchbox':
        final launched = await _systemControlService.webSearch(query);
        return AppTaskExecutionResult(
          status: launched
              ? AppTaskExecutionStatus.success
              : AppTaskExecutionStatus.failed,
          message: launched ? 'تم فتح البحث: $query' : 'تعذر تنفيذ البحث',
          task: task,
        );

      default:
        final opened = await _appControlService.openResolvedApp(
          ResolvedApp(
            packageName: packageName,
            displayName: task.targetAppName ?? packageName,
            spokenName: task.targetAppName ?? packageName,
            matchType: AppMatchType.catalogEntry,
          ),
        );

        return AppTaskExecutionResult(
          status: opened
              ? AppTaskExecutionStatus.partialSuccess
              : AppTaskExecutionStatus.failed,
          message: opened
              ? 'تم فتح التطبيق لكن البحث الداخلي غير مدعوم حاليًا'
              : 'تعذر فتح التطبيق للبحث داخله',
          task: task,
        );
    }
  }

  // ================================
  // STORE LISTING
  // ================================

  Future<AppTaskExecutionResult> _executeOpenStoreListing(
    AppTaskModel task,
  ) async {
    final appName = task.storeAppName?.trim();

    if (appName == null || appName.isEmpty) {
      return const AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'لم يتم تحديد اسم التطبيق داخل المتجر',
      );
    }

    final opened = await _playStoreService.openAppListingByName(appName);

    return AppTaskExecutionResult(
      status: opened
          ? AppTaskExecutionStatus.success
          : AppTaskExecutionStatus.failed,
      message: opened
          ? task.taskType == AppTaskType.installApp
              ? 'تم فتح صفحة التطبيق لتثبيته'
              : 'تم فتح المتجر على التطبيق المطلوب'
          : 'تعذر فتح المتجر على التطبيق المطلوب',
      task: task,
    );
  }

  // ================================
  // STORE SEARCH
  // ================================

  Future<AppTaskExecutionResult> _executeSearchStore(
    AppTaskModel task,
  ) async {
    final appName = task.storeAppName?.trim() ?? task.searchQuery?.trim();

    if (appName == null || appName.isEmpty) {
      return const AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'لم يتم تحديد اسم التطبيق المطلوب البحث عنه في المتجر',
      );
    }

    final opened = await _playStoreService.searchApp(appName);

    return AppTaskExecutionResult(
      status: opened
          ? AppTaskExecutionStatus.success
          : AppTaskExecutionStatus.failed,
      message: opened
          ? 'تم فتح البحث داخل المتجر: $appName'
          : 'تعذر فتح البحث داخل المتجر',
      task: task,
    );
  }

  // ================================
  // VPN TASKS
  // ================================

  Future<AppTaskExecutionResult> _executeVpnTask(
    AppTaskModel task,
  ) async {
    final appName = task.targetAppName?.trim();

    if (appName == null || appName.isEmpty) {
      return const AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'لم يتم تحديد تطبيق الـ VPN',
      );
    }

    final opened = await _tryOpenAppWithFallbacks(appName);

    if (!opened) {
      return AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'تعذر فتح تطبيق الـ VPN: $appName',
        task: task,
      );
    }

    return AppTaskExecutionResult(
      status: AppTaskExecutionStatus.partialSuccess,
      message: task.taskType == AppTaskType.connectVpn
          ? 'تم فتح تطبيق الـ VPN: $appName، والاتصال التلقائي يحتاج طبقة Automation لاحقة'
          : 'تم فتح تطبيق الـ VPN: $appName، والفصل التلقائي يحتاج طبقة Automation لاحقة',
      task: task,
    );
  }

  // ================================
  // INTERNAL HELPERS
  // ================================

  Future<bool> _tryOpenAppWithFallbacks(String appName) async {
    final directOpen = await _appControlService.openAppByName(appName);
    if (directOpen) {
      return true;
    }

    final resolved = await _appControlService.resolveApp(appName);
    if (resolved != null) {
      final openedResolved = await _appControlService.openResolvedApp(resolved);
      if (openedResolved) {
        return true;
      }
    }

    final matches = await _appControlService.searchApps(appName);
    if (matches.isNotEmpty) {
      final firstMatch = matches.first;
      return _appControlService.openResolvedApp(firstMatch);
    }

    return false;
  }
}

class AppTaskExecutionResult {
  const AppTaskExecutionResult({
    required this.status,
    required this.message,
    this.task,
  });

  final AppTaskExecutionStatus status;
  final String message;
  final AppTaskModel? task;

  bool get isSuccess =>
      status == AppTaskExecutionStatus.success ||
      status == AppTaskExecutionStatus.partialSuccess;
}

enum AppTaskExecutionStatus {
  success,
  partialSuccess,
  failed,
  invalidPlan,
  unsupported,
}

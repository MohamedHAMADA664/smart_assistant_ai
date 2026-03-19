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

    final opened = await _appControlService.openAppByName(appName);

    if (!opened) {
      return AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'تعذر فتح التطبيق',
        task: task,
      );
    }

    return AppTaskExecutionResult(
      status: AppTaskExecutionStatus.success,
      message: 'تم فتح التطبيق',
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
        final launched = await _musicService.playYoutube(query);
        return AppTaskExecutionResult(
          status: launched
              ? AppTaskExecutionStatus.success
              : AppTaskExecutionStatus.failed,
          message: launched
              ? 'تم فتح يوتيوب وتجهيز البحث'
              : 'تعذر تنفيذ البحث في يوتيوب',
          task: task,
        );

      case 'com.android.chrome':
      case 'com.google.android.googlequicksearchbox':
        final launched = await _systemControlService.webSearch(query);
        return AppTaskExecutionResult(
          status: launched
              ? AppTaskExecutionStatus.success
              : AppTaskExecutionStatus.failed,
          message: launched ? 'تم فتح البحث' : 'تعذر تنفيذ البحث',
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
          ? 'تم فتح المتجر على التطبيق المطلوب'
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
      message:
          opened ? 'تم فتح البحث داخل المتجر' : 'تعذر فتح البحث داخل المتجر',
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

    final opened = await _appControlService.openAppByName(appName);

    if (!opened) {
      return AppTaskExecutionResult(
        status: AppTaskExecutionStatus.failed,
        message: 'تعذر فتح تطبيق الـ VPN',
        task: task,
      );
    }

    return AppTaskExecutionResult(
      status: AppTaskExecutionStatus.partialSuccess,
      message: task.taskType == AppTaskType.connectVpn
          ? 'تم فتح تطبيق الـ VPN، والاتصال التلقائي يحتاج طبقة Automation لاحقة'
          : 'تم فتح تطبيق الـ VPN، والفصل التلقائي يحتاج طبقة Automation لاحقة',
      task: task,
    );
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

import '../models/app_task_model.dart';

class AppActionRegistryService {
  static const Map<String, AppCapabilityProfile> _profiles = {
    'com.whatsapp': AppCapabilityProfile(
      packageName: 'com.whatsapp',
      displayName: 'WhatsApp',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.openChat,
        AppTaskType.prepareMessage,
      },
      requiresInternetTasks: {
        AppTaskType.openChat,
        AppTaskType.prepareMessage,
      },
      requiresConfirmationTasks: {
        AppTaskType.prepareMessage,
      },
      requiresAutomationTasks: {},
    ),
    'com.whatsapp.w4b': AppCapabilityProfile(
      packageName: 'com.whatsapp.w4b',
      displayName: 'WhatsApp Business',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.openChat,
        AppTaskType.prepareMessage,
      },
      requiresInternetTasks: {
        AppTaskType.openChat,
        AppTaskType.prepareMessage,
      },
      requiresConfirmationTasks: {
        AppTaskType.prepareMessage,
      },
      requiresAutomationTasks: {},
    ),
    'org.telegram.messenger': AppCapabilityProfile(
      packageName: 'org.telegram.messenger',
      displayName: 'Telegram',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.openChat,
        AppTaskType.prepareMessage,
      },
      requiresInternetTasks: {
        AppTaskType.openChat,
        AppTaskType.prepareMessage,
      },
      requiresConfirmationTasks: {
        AppTaskType.prepareMessage,
      },
      requiresAutomationTasks: {},
    ),
    'com.google.android.youtube': AppCapabilityProfile(
      packageName: 'com.google.android.youtube',
      displayName: 'YouTube',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.searchInApp,
      },
      requiresInternetTasks: {
        AppTaskType.searchInApp,
      },
      requiresConfirmationTasks: {},
      requiresAutomationTasks: {},
    ),
    'com.android.vending': AppCapabilityProfile(
      packageName: 'com.android.vending',
      displayName: 'Google Play Store',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.searchStore,
        AppTaskType.openStoreListing,
      },
      requiresInternetTasks: {
        AppTaskType.searchStore,
        AppTaskType.openStoreListing,
      },
      requiresConfirmationTasks: {},
      requiresAutomationTasks: {},
    ),
    'com.google.android.gm': AppCapabilityProfile(
      packageName: 'com.google.android.gm',
      displayName: 'Gmail',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.prepareMessage,
      },
      requiresInternetTasks: {
        AppTaskType.prepareMessage,
      },
      requiresConfirmationTasks: {
        AppTaskType.prepareMessage,
      },
      requiresAutomationTasks: {},
    ),
    'com.google.android.apps.maps': AppCapabilityProfile(
      packageName: 'com.google.android.apps.maps',
      displayName: 'Google Maps',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.searchInApp,
      },
      requiresInternetTasks: {
        AppTaskType.searchInApp,
      },
      requiresConfirmationTasks: {},
      requiresAutomationTasks: {},
    ),
    'com.android.chrome': AppCapabilityProfile(
      packageName: 'com.android.chrome',
      displayName: 'Chrome',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.searchInApp,
      },
      requiresInternetTasks: {
        AppTaskType.searchInApp,
      },
      requiresConfirmationTasks: {},
      requiresAutomationTasks: {},
    ),
    'com.google.android.googlequicksearchbox': AppCapabilityProfile(
      packageName: 'com.google.android.googlequicksearchbox',
      displayName: 'Google App',
      supportedTasks: {
        AppTaskType.openApp,
        AppTaskType.searchInApp,
      },
      requiresInternetTasks: {
        AppTaskType.searchInApp,
      },
      requiresConfirmationTasks: {},
      requiresAutomationTasks: {},
    ),
  };

  static const Set<String> _vpnLikePackages = {
    'free.vpn.unblock.proxy.vpnmaster',
    'com.vpn.master',
  };

  AppCapabilityProfile getCapabilitiesForPackage(String packageName) {
    final normalizedPackageName = packageName.trim();

    final directProfile = _profiles[normalizedPackageName];
    if (directProfile != null) {
      return directProfile;
    }

    if (_isVpnLikePackage(normalizedPackageName)) {
      return AppCapabilityProfile(
        packageName: normalizedPackageName,
        displayName: 'VPN App',
        supportedTasks: const {
          AppTaskType.openApp,
          AppTaskType.connectVpn,
          AppTaskType.disconnectVpn,
        },
        requiresInternetTasks: const {
          AppTaskType.connectVpn,
          AppTaskType.disconnectVpn,
        },
        requiresConfirmationTasks: const {
          AppTaskType.connectVpn,
          AppTaskType.disconnectVpn,
        },
        requiresAutomationTasks: const {
          AppTaskType.connectVpn,
          AppTaskType.disconnectVpn,
        },
      );
    }

    return AppCapabilityProfile(
      packageName: normalizedPackageName,
      displayName: normalizedPackageName,
      supportedTasks: const {
        AppTaskType.openApp,
      },
      requiresInternetTasks: const {},
      requiresConfirmationTasks: const {},
      requiresAutomationTasks: const {},
    );
  }

  bool supportsTask({
    required String packageName,
    required AppTaskType taskType,
  }) {
    final profile = getCapabilitiesForPackage(packageName);
    return profile.supportedTasks.contains(taskType);
  }

  bool taskRequiresInternet({
    required String packageName,
    required AppTaskType taskType,
  }) {
    final profile = getCapabilitiesForPackage(packageName);
    return profile.requiresInternetTasks.contains(taskType);
  }

  bool taskRequiresConfirmation({
    required String packageName,
    required AppTaskType taskType,
  }) {
    final profile = getCapabilitiesForPackage(packageName);
    return profile.requiresConfirmationTasks.contains(taskType);
  }

  bool taskRequiresAutomation({
    required String packageName,
    required AppTaskType taskType,
  }) {
    final profile = getCapabilitiesForPackage(packageName);
    return profile.requiresAutomationTasks.contains(taskType);
  }

  List<AppTaskType> getSupportedTasks(String packageName) {
    final profile = getCapabilitiesForPackage(packageName);
    return profile.supportedTasks.toList();
  }

  bool _isVpnLikePackage(String packageName) {
    if (_vpnLikePackages.contains(packageName)) {
      return true;
    }

    final normalizedPackageName = packageName.toLowerCase();

    return normalizedPackageName.contains('vpn') ||
        normalizedPackageName.contains('proxy');
  }
}

class AppCapabilityProfile {
  const AppCapabilityProfile({
    required this.packageName,
    required this.displayName,
    required this.supportedTasks,
    required this.requiresInternetTasks,
    required this.requiresConfirmationTasks,
    required this.requiresAutomationTasks,
  });

  final String packageName;
  final String displayName;
  final Set<AppTaskType> supportedTasks;
  final Set<AppTaskType> requiresInternetTasks;
  final Set<AppTaskType> requiresConfirmationTasks;
  final Set<AppTaskType> requiresAutomationTasks;
}

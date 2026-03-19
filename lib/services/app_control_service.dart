import 'package:device_apps/device_apps.dart';

class AppControlService {
  static const Map<String, String> _knownApps = {
    'whatsapp': 'com.whatsapp',
    'واتساب': 'com.whatsapp',
    'واتس': 'com.whatsapp',
    'whatsapp business': 'com.whatsapp.w4b',
    'واتساب بيزنس': 'com.whatsapp.w4b',
    'واتساب بزنس': 'com.whatsapp.w4b',

    'youtube': 'com.google.android.youtube',
    'يوتيوب': 'com.google.android.youtube',

    'facebook': 'com.facebook.katana',
    'فيسبوك': 'com.facebook.katana',

    'instagram': 'com.instagram.android',
    'انستجرام': 'com.instagram.android',
    'تطبيق الانستا': 'com.instagram.android',

    'tiktok': 'com.zhiliaoapp.musically',
    'تيك توك': 'com.zhiliaoapp.musically',

    'telegram': 'org.telegram.messenger',
    'تليجرام': 'org.telegram.messenger',

    'maps': 'com.google.android.apps.maps',
    'google maps': 'com.google.android.apps.maps',
    'خرائط': 'com.google.android.apps.maps',
    'خرائط جوجل': 'com.google.android.apps.maps',

    'gmail': 'com.google.android.gm',
    'جيميل': 'com.google.android.gm',

    'chrome': 'com.android.chrome',
    'كروم': 'com.android.chrome',

    'google': 'com.google.android.googlequicksearchbox',
    'جوجل': 'com.google.android.googlequicksearchbox',

    'play store': 'com.android.vending',
    'المتجر': 'com.android.vending',
    'بلاي ستور': 'com.android.vending',

    'phone': 'com.google.android.dialer',
    'dialer': 'com.google.android.dialer',
    'الهاتف': 'com.google.android.dialer',
    'اتصال': 'com.google.android.dialer',

    'messages': 'com.google.android.apps.messaging',
    'sms': 'com.google.android.apps.messaging',
    'الرسائل': 'com.google.android.apps.messaging',
    'رسائل': 'com.google.android.apps.messaging',

    'youtube music': 'com.google.android.apps.youtube.music',
    'يوتيوب ميوزيك': 'com.google.android.apps.youtube.music',
    'music': 'com.google.android.apps.youtube.music',
    'موسيقى': 'com.google.android.apps.youtube.music',

    'spotify': 'com.spotify.music',
    'سبوتيفاي': 'com.spotify.music',
  };

  final List<Application> _installedApps = <Application>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  // ================================
  // LOAD INSTALLED APPS
  // ================================

  Future<void> loadInstalledApps({bool forceReload = false}) async {
    if (_loaded && !forceReload) {
      return;
    }

    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: false,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    _installedApps
      ..clear()
      ..addAll(apps);

    _loaded = true;
  }

  // ================================
  // OPEN APP BY NAME
  // ================================

  Future<bool> openAppByName(String name) async {
    final resolvedApp = await resolveApp(name);

    if (resolvedApp == null) {
      return false;
    }

    return openResolvedApp(resolvedApp);
  }

  // ================================
  // OPEN RESOLVED APP
  // ================================

  Future<bool> openResolvedApp(ResolvedApp resolvedApp) async {
    try {
      await DeviceApps.openApp(resolvedApp.packageName);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ================================
  // RESOLVE APP
  // ================================

  Future<ResolvedApp?> resolveApp(String spokenName) async {
    final normalizedName = _normalize(spokenName);
    if (normalizedName.isEmpty) {
      return null;
    }

    try {
      if (!_loaded) {
        await loadInstalledApps();
      }

      final knownPackage = _knownApps[normalizedName];
      if (knownPackage != null) {
        final installedApp = _findInstalledAppByPackage(knownPackage);

        if (installedApp != null) {
          return ResolvedApp(
            packageName: installedApp.packageName,
            displayName: installedApp.appName,
            spokenName: spokenName,
            matchType: AppMatchType.knownAlias,
          );
        }

        final isInstalled = await DeviceApps.isAppInstalled(knownPackage);
        if (isInstalled) {
          return ResolvedApp(
            packageName: knownPackage,
            displayName: normalizedName,
            spokenName: spokenName,
            matchType: AppMatchType.knownAlias,
          );
        }
      }

      Application? exactMatch;
      Application? partialMatch;
      Application? packageMatch;

      for (final app in _installedApps) {
        final appName = _normalize(app.appName);
        final packageName = _normalize(app.packageName);

        if (appName == normalizedName) {
          exactMatch = app;
          break;
        }

        if (packageMatch == null &&
            (packageName.contains(normalizedName) ||
                normalizedName.contains(packageName))) {
          packageMatch = app;
        }

        if (partialMatch == null && _isPartialMatch(appName, normalizedName)) {
          partialMatch = app;
        }
      }

      final targetApp = exactMatch ?? partialMatch ?? packageMatch;

      if (targetApp == null) {
        return null;
      }

      return ResolvedApp(
        packageName: targetApp.packageName,
        displayName: targetApp.appName,
        spokenName: spokenName,
        matchType: exactMatch != null
            ? AppMatchType.exactInstalledMatch
            : AppMatchType.partialInstalledMatch,
      );
    } catch (_) {
      return null;
    }
  }

  // ================================
  // SEARCH APPS
  // ================================

  Future<List<ResolvedApp>> searchApps(String query) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return <ResolvedApp>[];
    }

    if (!_loaded) {
      await loadInstalledApps();
    }

    final results = <ResolvedApp>[];

    for (final app in _installedApps) {
      final appName = _normalize(app.appName);
      final packageName = _normalize(app.packageName);

      if (_isPartialMatch(appName, normalizedQuery) ||
          packageName.contains(normalizedQuery)) {
        results.add(
          ResolvedApp(
            packageName: app.packageName,
            displayName: app.appName,
            spokenName: query,
            matchType: appName == normalizedQuery
                ? AppMatchType.exactInstalledMatch
                : AppMatchType.partialInstalledMatch,
          ),
        );
      }
    }

    return results;
  }

  // ================================
  // GET INSTALLED APP SNAPSHOT
  // ================================

  Future<List<ResolvedApp>> getInstalledAppsSnapshot() async {
    if (!_loaded) {
      await loadInstalledApps();
    }

    return _installedApps
        .map(
          (app) => ResolvedApp(
            packageName: app.packageName,
            displayName: app.appName,
            spokenName: app.appName,
            matchType: AppMatchType.catalogEntry,
          ),
        )
        .toList();
  }

  // ================================
  // HELPERS
  // ================================

  Application? _findInstalledAppByPackage(String packageName) {
    for (final app in _installedApps) {
      if (app.packageName == packageName) {
        return app;
      }
    }

    return null;
  }

  bool _isPartialMatch(String appName, String spokenName) {
    return appName.contains(spokenName) ||
        spokenName.contains(appName) ||
        _containsAllWords(appName, spokenName) ||
        _containsAllWords(spokenName, appName);
  }

  bool _containsAllWords(String source, String query) {
    final words = query.split(' ').where((word) => word.trim().isNotEmpty);
    if (words.isEmpty) {
      return false;
    }

    for (final word in words) {
      if (!source.contains(word)) {
        return false;
      }
    }

    return true;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class ResolvedApp {
  const ResolvedApp({
    required this.packageName,
    required this.displayName,
    required this.spokenName,
    required this.matchType,
  });

  final String packageName;
  final String displayName;
  final String spokenName;
  final AppMatchType matchType;
}

enum AppMatchType {
  knownAlias,
  exactInstalledMatch,
  partialInstalledMatch,
  catalogEntry,
}

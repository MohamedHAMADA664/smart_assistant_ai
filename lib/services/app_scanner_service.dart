import 'package:device_apps/device_apps.dart';

class AppScannerService {
  final Map<String, String> _apps = <String, String>{};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  Map<String, String> get scannedApps =>
      Map<String, String>.unmodifiable(_apps);

  // ===============================
  // SCAN INSTALLED APPS
  // ===============================

  Future<void> scanInstalledApps({bool forceReload = false}) async {
    if (_loaded && !forceReload) {
      return;
    }

    final apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: false,
      includeAppIcons: false,
      onlyAppsWithLaunchIntent: true,
    );

    _apps.clear();

    for (final app in apps) {
      final normalizedName = _normalize(app.appName);

      if (normalizedName.isEmpty) {
        continue;
      }

      _apps[normalizedName] = app.packageName;
    }

    _loaded = true;
  }

  // ===============================
  // FIND APP BY NAME
  // ===============================

  Future<String?> findAppPackage(String name) async {
    if (!_loaded) {
      await scanInstalledApps();
    }

    final normalizedName = _normalize(name);
    if (normalizedName.isEmpty) {
      return null;
    }

    String? partialMatch;

    for (final entry in _apps.entries) {
      if (entry.key == normalizedName) {
        return entry.value;
      }

      if (partialMatch == null && entry.key.contains(normalizedName)) {
        partialMatch = entry.value;
      }
    }

    return partialMatch;
  }

  // ===============================
  // HELPERS
  // ===============================

  String _normalize(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

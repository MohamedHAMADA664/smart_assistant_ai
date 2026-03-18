import 'package:device_apps/device_apps.dart';

class AppScannerService {
  final Map<String, String> _apps = {};

  // ===============================
  // SCAN INSTALLED APPS
  // ===============================

  Future<void> scanInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: false,
      includeAppIcons: false,
    );

    for (var app in apps) {
      String name = app.appName.toLowerCase();

      _apps[name] = app.packageName;
    }
  }

  // ===============================
  // FIND APP BY NAME
  // ===============================

  String? findAppPackage(String name) {
    name = name.toLowerCase();

    for (var appName in _apps.keys) {
      if (appName.contains(name)) {
        return _apps[appName];
      }
    }

    return null;
  }
}

import 'package:device_apps/device_apps.dart';

class AppControlService {
  List<Application> _installedApps = [];

  bool _loaded = false;

  // ================================
  // LOAD INSTALLED APPS
  // ================================

  Future<void> loadInstalledApps() async {
    if (_loaded) return;

    _installedApps = await DeviceApps.getInstalledApplications(
      includeAppIcons: false,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );

    _loaded = true;
  }

  // ================================
  // OPEN APP BY NAME (KNOWN APPS)
  // ================================

  Future<bool> openAppByName(String name) async {
    name = name.toLowerCase();

    Map<String, String> apps = {
      "whatsapp": "com.whatsapp",
      "واتساب": "com.whatsapp",
      "youtube": "com.google.android.youtube",
      "يوتيوب": "com.google.android.youtube",
      "facebook": "com.facebook.katana",
      "فيسبوك": "com.facebook.katana",
      "instagram": "com.instagram.android",
      "انستجرام": "com.instagram.android",
      "tiktok": "com.zhiliaoapp.musically",
      "تيك توك": "com.zhiliaoapp.musically",
      "telegram": "org.telegram.messenger",
      "تليجرام": "org.telegram.messenger",
      "maps": "com.google.android.apps.maps",
      "خرائط": "com.google.android.apps.maps",
      "gmail": "com.google.android.gm",
      "chrome": "com.android.chrome",
    };

    if (apps.containsKey(name)) {
      String packageName = apps[name]!;

      bool installed = await DeviceApps.isAppInstalled(packageName);

      if (installed) {
        await DeviceApps.openApp(packageName);

        return true;
      }
    }

    return false;
  }

  // ================================
  // TRY OPEN ANY APP DYNAMICALLY
  // ================================

  Future<bool> tryOpenDynamicApp(String spokenWord) async {
    spokenWord = spokenWord.toLowerCase();

    if (!_loaded) {
      await loadInstalledApps();
    }

    for (Application app in _installedApps) {
      String appName = app.appName.toLowerCase();

      if (appName.contains(spokenWord)) {
        await DeviceApps.openApp(app.packageName);

        return true;
      }
    }

    return false;
  }
}

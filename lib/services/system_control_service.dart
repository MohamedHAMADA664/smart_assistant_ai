import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔥 جديد

class SystemControlService {
  // ================================
  // WIFI SETTINGS
  // ================================

  Future<void> openWifiSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.WIFI_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }

  // ================================
  // BLUETOOTH SETTINGS
  // ================================

  Future<void> openBluetoothSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.BLUETOOTH_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }

  // ================================
  // MOBILE DATA SETTINGS
  // ================================

  Future<void> openMobileDataSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.DATA_ROAMING_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }

  // ================================
  // LOCATION SETTINGS
  // ================================

  Future<void> openLocationSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }

  // ================================
  // GENERAL SETTINGS
  // ================================

  Future<void> openSystemSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }

  // ================================
  // 🔥 WEB SEARCH (حل المشكلة)
  // ================================

  Future<void> webSearch(String query) async {
    if (query.trim().isEmpty) {
      print("Empty search query");
      return;
    }

    final url = "https://www.google.com/search?q=${Uri.encodeComponent(query)}";

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Error opening browser");
    }
  }

  // ================================
  // VOLUME CONTROL
  // ================================

  Future<void> increaseVolume() async {
    double volume = await VolumeController().getVolume();

    volume += 0.1;

    if (volume > 1) {
      volume = 1;
    }

    VolumeController().setVolume(volume);
  }

  Future<void> decreaseVolume() async {
    double volume = await VolumeController().getVolume();

    volume -= 0.1;

    if (volume < 0) {
      volume = 0;
    }

    VolumeController().setVolume(volume);
  }

  Future<void> muteVolume() async {
    VolumeController().setVolume(0);
  }

  // ================================
  // ALIAS FUNCTIONS (FIX ERRORS)
  // ================================

  Future<void> volumeUp() async {
    await increaseVolume();
  }

  Future<void> volumeDown() async {
    await decreaseVolume();
  }
}

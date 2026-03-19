import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volume_controller/volume_controller.dart';

class SystemControlService {
  SystemControlService({
    VolumeController? volumeController,
  }) : _volumeController = volumeController ?? VolumeController();

  final VolumeController _volumeController;

  // ================================
  // WIFI SETTINGS
  // ================================

  Future<bool> openWifiSettings() {
    return _launchAndroidSettings('android.settings.WIFI_SETTINGS');
  }

  // ================================
  // BLUETOOTH SETTINGS
  // ================================

  Future<bool> openBluetoothSettings() {
    return _launchAndroidSettings('android.settings.BLUETOOTH_SETTINGS');
  }

  // ================================
  // MOBILE DATA SETTINGS
  // ================================

  Future<bool> openMobileDataSettings() {
    return _launchAndroidSettings('android.settings.DATA_ROAMING_SETTINGS');
  }

  // ================================
  // LOCATION SETTINGS
  // ================================

  Future<bool> openLocationSettings() {
    return _launchAndroidSettings('android.settings.LOCATION_SOURCE_SETTINGS');
  }

  // ================================
  // GENERAL SETTINGS
  // ================================

  Future<bool> openSystemSettings() {
    return _launchAndroidSettings('android.settings.SETTINGS');
  }

  // ================================
  // WEB SEARCH
  // ================================

  Future<bool> webSearch(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return false;
    }

    final uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(normalizedQuery)}',
    );

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

  // ================================
  // VOLUME CONTROL
  // ================================

  Future<void> increaseVolume() async {
    final currentVolume = await _volumeController.getVolume();
    final newVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
    await _volumeController.setVolume(newVolume);
  }

  Future<void> decreaseVolume() async {
    final currentVolume = await _volumeController.getVolume();
    final newVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
    await _volumeController.setVolume(newVolume);
  }

  Future<void> muteVolume() async {
    await _volumeController.setVolume(0.0);
  }

  // ================================
  // ALIASES
  // ================================

  Future<void> volumeUp() => increaseVolume();

  Future<void> volumeDown() => decreaseVolume();

  // ================================
  // HELPERS
  // ================================

  Future<bool> _launchAndroidSettings(String action) async {
    const flags = <int>[Flag.FLAG_ACTIVITY_NEW_TASK];

    final intent = AndroidIntent(
      action: action,
      flags: flags,
    );

    try {
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }
}

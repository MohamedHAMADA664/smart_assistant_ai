import 'package:url_launcher/url_launcher.dart';

class PlayStoreService {
  static const String _playStorePackageName = 'com.android.vending';

  // ================================
  // OPEN PLAY STORE APP
  // ================================

  Future<bool> openStore() async {
    final marketUri = Uri.parse('market://search?q=');

    try {
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
      }

      final webUri = Uri.parse('https://play.google.com/store');
      return await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  // ================================
  // SEARCH APP IN PLAY STORE
  // ================================

  Future<bool> searchApp(String appName) async {
    final normalizedAppName = _normalize(appName);
    if (normalizedAppName.isEmpty) {
      return false;
    }

    final marketUri = Uri.parse(
      'market://search?q=${Uri.encodeComponent(normalizedAppName)}&c=apps',
    );

    final webUri = Uri.parse(
      'https://play.google.com/store/search?q=${Uri.encodeComponent(normalizedAppName)}&c=apps',
    );

    return _launchWithFallback(
      primaryUri: marketUri,
      fallbackUri: webUri,
    );
  }

  // ================================
  // OPEN APP LISTING BY PACKAGE NAME
  // ================================

  Future<bool> openAppListingByPackage(String packageName) async {
    final normalizedPackageName = _normalize(packageName);
    if (normalizedPackageName.isEmpty) {
      return false;
    }

    final marketUri = Uri.parse(
      'market://details?id=$normalizedPackageName',
    );

    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$normalizedPackageName',
    );

    return _launchWithFallback(
      primaryUri: marketUri,
      fallbackUri: webUri,
    );
  }

  // ================================
  // OPEN APP LISTING BY APP NAME
  // ================================

  Future<bool> openAppListingByName(String appName) async {
    final normalizedAppName = _normalize(appName);
    if (normalizedAppName.isEmpty) {
      return false;
    }

    return searchApp(normalizedAppName);
  }

  // ================================
  // BUILD STORE INTENT DATA
  // ================================

  StoreTarget buildStoreTarget({
    String? appName,
    String? packageName,
  }) {
    final normalizedAppName = _normalize(appName);
    final normalizedPackageName = _normalize(packageName);

    return StoreTarget(
      appName: normalizedAppName.isEmpty ? null : normalizedAppName,
      packageName: normalizedPackageName.isEmpty ? null : normalizedPackageName,
      storePackageName: _playStorePackageName,
    );
  }

  // ================================
  // HELPERS
  // ================================

  Future<bool> _launchWithFallback({
    required Uri primaryUri,
    required Uri fallbackUri,
  }) async {
    try {
      if (await canLaunchUrl(primaryUri)) {
        final launchedPrimary = await launchUrl(
          primaryUri,
          mode: LaunchMode.externalApplication,
        );

        if (launchedPrimary) {
          return true;
        }
      }

      return await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  String _normalize(String? text) {
    return (text ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class StoreTarget {
  const StoreTarget({
    required this.appName,
    required this.packageName,
    required this.storePackageName,
  });

  final String? appName;
  final String? packageName;
  final String storePackageName;

  bool get hasAppName => appName != null && appName!.isNotEmpty;

  bool get hasPackageName => packageName != null && packageName!.isNotEmpty;
}

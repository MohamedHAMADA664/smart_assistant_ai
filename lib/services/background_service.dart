import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }
}

void onStart(ServiceInstance service) {
  service.on("stopService").listen((event) {
    service.stopSelf();
  });
}

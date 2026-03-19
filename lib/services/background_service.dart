import 'background_assistant_service.dart';

@Deprecated(
  'Use BackgroundAssistantService instead. '
  'This class is kept temporarily for backward compatibility only.',
)
class BackgroundService {
  static Future<void> initializeService() async {
    await BackgroundAssistantService.startService();
  }

  static Future<void> stopService() async {
    await BackgroundAssistantService.stopService();
  }
}

import 'phone_lookup_service.dart';

class CallBlockService {
  final PhoneLookupService _lookupService = PhoneLookupService();

  bool shouldBlock(String phone) {
    var result = _lookupService.lookupNumber(phone);

    if (result != null) {
      bool spam = result["spam"] ?? false;

      if (spam) {
        return true;
      }
    }

    return false;
  }
}

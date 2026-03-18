class PhoneLookupService {
  static final Map<String, Map<String, dynamic>> _communityDatabase = {
    "01012345678": {"name": "شركة شحن", "spam": false},
    "01198765432": {"name": "مكالمات تسويق", "spam": true}
  };

  Map<String, dynamic>? lookupNumber(String phone) {
    if (_communityDatabase.containsKey(phone)) {
      return _communityDatabase[phone];
    }

    return null;
  }
}

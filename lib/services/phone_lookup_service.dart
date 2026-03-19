class PhoneLookupService {
  static const Map<String, PhoneLookupRecord> _communityDatabase = {
    '01012345678': PhoneLookupRecord(
      name: 'شركة شحن',
      isSpam: false,
    ),
    '01198765432': PhoneLookupRecord(
      name: 'مكالمات تسويق',
      isSpam: true,
    ),
  };

  // ================================
  // LOOKUP NUMBER
  // ================================

  Future<Map<String, dynamic>?> lookupNumber(String phone) async {
    final normalizedPhone = _normalizePhone(phone);

    if (normalizedPhone.isEmpty) {
      return null;
    }

    final record = _communityDatabase[normalizedPhone];
    if (record == null) {
      return null;
    }

    return {
      'phone': normalizedPhone,
      'name': record.name,
      'spam': record.isSpam,
    };
  }

  // ================================
  // OPTIONAL TYPED LOOKUP
  // ================================

  Future<PhoneLookupRecord?> lookupRecord(String phone) async {
    final normalizedPhone = _normalizePhone(phone);

    if (normalizedPhone.isEmpty) {
      return null;
    }

    return _communityDatabase[normalizedPhone];
  }

  // ================================
  // HELPERS
  // ================================

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class PhoneLookupRecord {
  const PhoneLookupRecord({
    required this.name,
    required this.isSpam,
  });

  final String name;
  final bool isSpam;
}

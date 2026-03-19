import 'phone_lookup_service.dart';

class CallBlockService {
  CallBlockService({
    PhoneLookupService? phoneLookupService,
  }) : _lookupService = phoneLookupService ?? PhoneLookupService();

  final PhoneLookupService _lookupService;

  // ================================
  // SHOULD BLOCK
  // ================================

  Future<bool> shouldBlock(String phone) async {
    final result = await evaluateNumber(phone);
    return result.shouldBlock;
  }

  // ================================
  // EVALUATE NUMBER
  // ================================

  Future<CallBlockDecision> evaluateNumber(String phone) async {
    final normalizedPhone = _normalizePhone(phone);

    if (normalizedPhone.isEmpty) {
      return const CallBlockDecision(
        shouldBlock: false,
        isKnownNumber: false,
        isSpam: false,
      );
    }

    final result = await _lookupService.lookupNumber(normalizedPhone);

    if (result == null) {
      return const CallBlockDecision(
        shouldBlock: false,
        isKnownNumber: false,
        isSpam: false,
      );
    }

    final isSpam = result['spam'] == true;

    return CallBlockDecision(
      shouldBlock: isSpam,
      isKnownNumber: true,
      isSpam: isSpam,
      rawData: result,
    );
  }

  // ================================
  // HELPERS
  // ================================

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class CallBlockDecision {
  const CallBlockDecision({
    required this.shouldBlock,
    required this.isKnownNumber,
    required this.isSpam,
    this.rawData,
  });

  final bool shouldBlock;
  final bool isKnownNumber;
  final bool isSpam;
  final Map<String, dynamic>? rawData;
}

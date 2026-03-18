import 'package:flutter_contacts/flutter_contacts.dart';

class ContactCallService {
  List<Contact> contacts = [];

  // ================================
  // LOAD CONTACTS
  // ================================

  Future<void> loadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
    }
  }

  // ================================
  // FIND CONTACT NAME
  // ================================

  String findContactName(String number) {
    number = _normalizeNumber(number);

    for (var contact in contacts) {
      for (var phone in contact.phones) {
        String contactNumber = _normalizeNumber(phone.number);

        // 🔥 مقارنة ذكية
        if (contactNumber.endsWith(number) || number.endsWith(contactNumber)) {
          return contact.displayName;
        }
      }
    }

    return "رقم غير معروف"; // 🔥 مهم جدًا
  }

  // ================================
  // NORMALIZE NUMBER (🔥 احترافي)
  // ================================

  String _normalizeNumber(String number) {
    number = number
        .replaceAll(" ", "")
        .replaceAll("-", "")
        .replaceAll("+", "")
        .replaceAll("(", "")
        .replaceAll(")", "");

    // 🔥 تحويل +20 → 0
    if (number.startsWith("20")) {
      number = "0${number.substring(2)}";
    }

    return number;
  }
}

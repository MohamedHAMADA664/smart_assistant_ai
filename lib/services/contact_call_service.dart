import 'package:flutter_contacts/flutter_contacts.dart';

class ContactCallService {
  final List<Contact> _contacts = <Contact>[];

  bool _loaded = false;
  bool _permissionGranted = false;

  List<Contact> get contacts => List<Contact>.unmodifiable(_contacts);

  bool get isLoaded => _loaded;
  bool get hasPermission => _permissionGranted;

  // ================================
  // LOAD CONTACTS
  // ================================

  Future<bool> loadContacts({bool forceReload = false}) async {
    if (_loaded && !forceReload) {
      return _permissionGranted;
    }

    _permissionGranted = await FlutterContacts.requestPermission();

    if (!_permissionGranted) {
      _contacts.clear();
      _loaded = false;
      return false;
    }

    final loadedContacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    _contacts
      ..clear()
      ..addAll(loadedContacts);

    _loaded = true;
    return true;
  }

  // ================================
  // FIND CONTACT NAME
  // ================================

  Future<String> findContactName(String number) async {
    final foundContact = await findContactByNumber(number);
    return foundContact?.displayName ?? 'رقم غير معروف';
  }

  // ================================
  // FIND CONTACT BY NUMBER
  // ================================

  Future<Contact?> findContactByNumber(String number) async {
    if (!_loaded) {
      await loadContacts();
    }

    final normalizedIncomingNumber = _normalizeNumber(number);
    if (normalizedIncomingNumber.isEmpty) {
      return null;
    }

    for (final contact in _contacts) {
      for (final phone in contact.phones) {
        final normalizedContactNumber = _normalizeNumber(phone.number);

        if (normalizedContactNumber.isEmpty) {
          continue;
        }

        if (normalizedContactNumber.endsWith(normalizedIncomingNumber) ||
            normalizedIncomingNumber.endsWith(normalizedContactNumber)) {
          return contact;
        }
      }
    }

    return null;
  }

  // ================================
  // FIND CONTACTS BY NAME
  // ================================

  Future<List<Contact>> findContactsByName(String name) async {
    if (!_loaded) {
      await loadContacts();
    }

    final normalizedName = _normalizeText(name);
    if (normalizedName.isEmpty) {
      return <Contact>[];
    }

    return _contacts.where((contact) {
      final displayName = _normalizeText(contact.displayName);
      return displayName.contains(normalizedName);
    }).toList();
  }

  // ================================
  // HELPERS
  // ================================

  String _normalizeNumber(String number) {
    var normalized = number.replaceAll(RegExp(r'[^0-9]'), '');

    if (normalized.startsWith('20') && normalized.length >= 11) {
      normalized = '0${normalized.substring(2)}';
    }

    return normalized;
  }

  String _normalizeText(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

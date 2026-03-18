class IntentModel {
  final String action;
  final String? appName;
  final String? contactName;
  final String? query;

  IntentModel({
    required this.action,
    this.appName,
    this.contactName,
    this.query,
  });
}

class AppTaskModel {
  const AppTaskModel({
    required this.taskType,
    this.targetAppName,
    this.targetPackageName,
    this.contactName,
    this.messageText,
    this.searchQuery,
    this.storeAppName,
    this.serverName,
    this.requiresConfirmation = false,
    this.requiresInternet = false,
    this.requiresAutomation = false,
    this.metadata = const <String, String>{},
  });

  final AppTaskType taskType;

  final String? targetAppName;
  final String? targetPackageName;

  final String? contactName;
  final String? messageText;
  final String? searchQuery;
  final String? storeAppName;
  final String? serverName;

  final bool requiresConfirmation;
  final bool requiresInternet;
  final bool requiresAutomation;

  final Map<String, String> metadata;

  bool get hasTargetApp =>
      (targetAppName != null && targetAppName!.trim().isNotEmpty) ||
      (targetPackageName != null && targetPackageName!.trim().isNotEmpty);

  bool get hasMessage => messageText != null && messageText!.trim().isNotEmpty;

  bool get hasContact => contactName != null && contactName!.trim().isNotEmpty;

  bool get hasSearchQuery =>
      searchQuery != null && searchQuery!.trim().isNotEmpty;

  bool get hasStoreAppName =>
      storeAppName != null && storeAppName!.trim().isNotEmpty;

  bool get hasServerName => serverName != null && serverName!.trim().isNotEmpty;

  AppTaskModel copyWith({
    AppTaskType? taskType,
    String? targetAppName,
    String? targetPackageName,
    String? contactName,
    String? messageText,
    String? searchQuery,
    String? storeAppName,
    String? serverName,
    bool? requiresConfirmation,
    bool? requiresInternet,
    bool? requiresAutomation,
    Map<String, String>? metadata,
    bool clearTargetAppName = false,
    bool clearTargetPackageName = false,
    bool clearContactName = false,
    bool clearMessageText = false,
    bool clearSearchQuery = false,
    bool clearStoreAppName = false,
    bool clearServerName = false,
  }) {
    return AppTaskModel(
      taskType: taskType ?? this.taskType,
      targetAppName:
          clearTargetAppName ? null : (targetAppName ?? this.targetAppName),
      targetPackageName: clearTargetPackageName
          ? null
          : (targetPackageName ?? this.targetPackageName),
      contactName: clearContactName ? null : (contactName ?? this.contactName),
      messageText: clearMessageText ? null : (messageText ?? this.messageText),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      storeAppName:
          clearStoreAppName ? null : (storeAppName ?? this.storeAppName),
      serverName: clearServerName ? null : (serverName ?? this.serverName),
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      requiresInternet: requiresInternet ?? this.requiresInternet,
      requiresAutomation: requiresAutomation ?? this.requiresAutomation,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskType': taskType.name,
      'targetAppName': targetAppName,
      'targetPackageName': targetPackageName,
      'contactName': contactName,
      'messageText': messageText,
      'searchQuery': searchQuery,
      'storeAppName': storeAppName,
      'serverName': serverName,
      'requiresConfirmation': requiresConfirmation,
      'requiresInternet': requiresInternet,
      'requiresAutomation': requiresAutomation,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'AppTaskModel('
        'taskType: ${taskType.name}, '
        'targetAppName: $targetAppName, '
        'targetPackageName: $targetPackageName, '
        'contactName: $contactName, '
        'messageText: $messageText, '
        'searchQuery: $searchQuery, '
        'storeAppName: $storeAppName, '
        'serverName: $serverName, '
        'requiresConfirmation: $requiresConfirmation, '
        'requiresInternet: $requiresInternet, '
        'requiresAutomation: $requiresAutomation, '
        'metadata: $metadata'
        ')';
  }
}

enum AppTaskType {
  openApp,
  openChat,
  prepareMessage,
  sendMessage,
  searchInApp,
  openStoreListing,
  searchStore,
  installApp,
  connectVpn,
  disconnectVpn,
  openSettingsInApp,
  unknown,
}

enum MutationAction {
  create,
  update,
  delete,
}

enum SyncStatus {
  pending,
  synced,
  failed,
}

class MutationLogEntry {
  final String logId;
  final DateTime timestamp;
  final MutationAction action;
  final String entityId;
  final Map<String, dynamic> payload;
  SyncStatus syncStatus;
  DateTime? syncedAt;
  String? errorMessage;

  MutationLogEntry({
    required this.logId,
    required this.timestamp,
    required this.action,
    required this.entityId,
    required this.payload,
    this.syncStatus = SyncStatus.pending,
    this.syncedAt,
    this.errorMessage,
  });

  String get actionName => action.name.toUpperCase();

  String get description {
    final subject = payload['subject'] ?? 'Slot $entityId';
    switch (action) {
      case MutationAction.create:
        return 'Created "$subject"';
      case MutationAction.update:
        return 'Updated "$subject"';
      case MutationAction.delete:
        return 'Deleted "$subject"';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'timestamp': timestamp.toIso8601String(),
      'action': action.name,
      'entityId': entityId,
      'payload': payload,
      'syncStatus': syncStatus.name,
      'syncedAt': syncedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory MutationLogEntry.fromJson(Map<String, dynamic> json) {
    return MutationLogEntry(
      logId: json['logId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: MutationAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => MutationAction.update,
      ),
      entityId: json['entityId'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

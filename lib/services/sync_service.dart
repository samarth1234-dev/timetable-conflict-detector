import '../models/time_slot.dart';
import '../models/mutation_log.dart';
import 'mock_remote_server.dart';
import 'storage_service.dart';

class SyncResult {
  final int syncedCount;
  final int pulledCount;
  final int conflictCount;
  final String message;
  final bool success;

  const SyncResult({
    required this.syncedCount,
    required this.pulledCount,
    required this.conflictCount,
    required this.message,
    required this.success,
  });
}

class SyncService {
  final StorageService _storage;
  final MockRemoteServer _server;

  SyncService(this._storage, this._server);

  /// Performs full bi-directional reconciliation:
  /// 1. Push all pending local mutations to the remote server in FIFO order.
  /// 2. Pull authoritative remote state.
  /// 3. Reconcile remote slots with local state using Last-Write-Wins (LWW).
  Future<SyncResult> synchronize({
    required List<TimeSlot> localSlots,
    required List<MutationLogEntry> mutationLogs,
  }) async {
    int syncedCount = 0;
    int pulledCount = 0;
    int conflictCount = 0;

    try {
      // Step 1: Push pending mutations in order of creation
      final pendingLogs = mutationLogs
          .where((m) => m.syncStatus == SyncStatus.pending)
          .toList();

      pendingLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (final mutation in pendingLogs) {
        try {
          await _server.applyMutation(mutation);
          mutation.syncStatus = SyncStatus.synced;
          mutation.syncedAt = DateTime.now();
          mutation.errorMessage = null;
          syncedCount++;
        } catch (e) {
          mutation.syncStatus = SyncStatus.failed;
          mutation.errorMessage = e.toString();
        }
      }

      // Step 2: Fetch remote state
      final remoteSlots = await _server.fetchRemoteSlots();

      // Step 3: Reconcile remote slots into local state
      final Map<String, TimeSlot> localMap = {
        for (var s in localSlots) s.id: s
      };

      for (final remoteSlot in remoteSlots) {
        if (!localMap.containsKey(remoteSlot.id)) {
          // New entity from server
          localMap[remoteSlot.id] = remoteSlot;
          pulledCount++;
        } else {
          final localSlot = localMap[remoteSlot.id]!;

          // If there is still a pending local mutation for this entity, local wins
          final hasPending = pendingLogs.any((m) => m.entityId == remoteSlot.id && m.syncStatus == SyncStatus.pending);

          if (!hasPending) {
            // Reconcile via Last-Write-Wins (LWW) and version comparison
            if (remoteSlot.version > localSlot.version ||
                remoteSlot.updatedAt.isAfter(localSlot.updatedAt)) {
              localMap[remoteSlot.id] = remoteSlot;
              conflictCount++;
            }
          }
        }
      }

      // Update local slots list
      localSlots.clear();
      localSlots.addAll(localMap.values);

      // Persist reconciled state and logs
      await _storage.saveSlots(localSlots);
      await _storage.saveMutationLogs(mutationLogs);

      return SyncResult(
        syncedCount: syncedCount,
        pulledCount: pulledCount,
        conflictCount: conflictCount,
        message: 'Sync succeeded: $syncedCount pushed, $pulledCount pulled, $conflictCount reconciled.',
        success: true,
      );
    } catch (e) {
      return SyncResult(
        syncedCount: syncedCount,
        pulledCount: pulledCount,
        conflictCount: conflictCount,
        message: 'Sync error: $e',
        success: false,
      );
    }
  }
}

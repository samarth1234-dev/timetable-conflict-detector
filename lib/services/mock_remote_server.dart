import 'storage_service.dart';
import '../models/time_slot.dart';
import '../models/mutation_log.dart';

class MockRemoteServer {
  final StorageService _storage;
  List<TimeSlot> _remoteSlots = [];

  MockRemoteServer(this._storage) {
    _remoteSlots = _storage.loadRemoteSlots();
  }

  List<TimeSlot> get currentSlots => List.unmodifiable(_remoteSlots);

  Future<void> seedIfEmpty(List<TimeSlot> initialSlots) async {
    if (_remoteSlots.isEmpty) {
      _remoteSlots = List.from(initialSlots);
      await _storage.saveRemoteSlots(_remoteSlots);
    }
  }

  /// Simulates network latency (200ms)
  Future<void> _simulateLatency() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Fetches all active and tombstoned slots from the server
  Future<List<TimeSlot>> fetchRemoteSlots() async {
    await _simulateLatency();
    return _remoteSlots.map((s) => s.copyWith()).toList();
  }

  /// Applies a client mutation to the remote server using Last-Write-Wins (LWW) reconciliation.
  Future<TimeSlot?> applyMutation(MutationLogEntry mutation) async {
    await _simulateLatency();
    final payload = mutation.payload;
    final entityId = mutation.entityId;

    final existingIndex = _remoteSlots.indexWhere((s) => s.id == entityId);

    switch (mutation.action) {
      case MutationAction.create:
        final clientSlot = TimeSlot.fromJson(payload);
        if (existingIndex >= 0) {
          // Slot already exists remotely. Apply Last-Write-Wins based on updatedAt
          final existing = _remoteSlots[existingIndex];
          if (clientSlot.updatedAt.isAfter(existing.updatedAt)) {
            _remoteSlots[existingIndex] = clientSlot.copyWith(
              version: existing.version + 1,
            );
          }
        } else {
          _remoteSlots.add(clientSlot);
        }
        await _storage.saveRemoteSlots(_remoteSlots);
        return _remoteSlots.firstWhere((s) => s.id == entityId);

      case MutationAction.update:
        final clientSlot = TimeSlot.fromJson(payload);
        if (existingIndex >= 0) {
          final existing = _remoteSlots[existingIndex];
          // LWW reconciliation
          if (clientSlot.updatedAt.isAfter(existing.updatedAt) ||
              clientSlot.version >= existing.version) {
            _remoteSlots[existingIndex] = clientSlot.copyWith(
              version: existing.version + 1,
            );
          }
        } else {
          // If not present remotely, treat as insert
          _remoteSlots.add(clientSlot);
        }
        await _storage.saveRemoteSlots(_remoteSlots);
        return _remoteSlots.firstWhere((s) => s.id == entityId);

      case MutationAction.delete:
        if (existingIndex >= 0) {
          _remoteSlots[existingIndex] = _remoteSlots[existingIndex].copyWith(
            isDeleted: true,
            updatedAt: mutation.timestamp,
            version: _remoteSlots[existingIndex].version + 1,
          );
        }
        await _storage.saveRemoteSlots(_remoteSlots);
        return null;
    }
  }

  /// Injects an external server change to simulate concurrent multi-user activity
  Future<TimeSlot> injectExternalServerSlot({
    required String subject,
    required int day,
    required int startMinutes,
    required int endMinutes,
    required String room,
    required String instructor,
    required int colorValue,
  }) async {
    final newSlot = TimeSlot(
      id: 'srv-${DateTime.now().millisecondsSinceEpoch}',
      subject: subject,
      day: day,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      room: room,
      instructor: instructor,
      colorValue: colorValue,
      updatedAt: DateTime.now(),
      version: 1,
    );

    _remoteSlots.add(newSlot);
    await _storage.saveRemoteSlots(_remoteSlots);
    return newSlot;
  }
}

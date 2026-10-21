import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/time_slot.dart';
import '../models/clash_result.dart';
import '../models/mutation_log.dart';
import '../services/clash_detector.dart';
import '../services/storage_service.dart';
import '../services/mock_remote_server.dart';
import '../services/sync_service.dart';

class TimetableController extends ChangeNotifier {
  final StorageService _storage;
  late final MockRemoteServer _remoteServer;
  late final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  List<TimeSlot> _slots = [];
  List<MutationLogEntry> _mutationLogs = [];
  ClashReport _clashReport = ClashReport.empty;

  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncStatusMessage;

  TimetableController(this._storage) {
    _remoteServer = MockRemoteServer(_storage);
    _syncService = SyncService(_storage, _remoteServer);
  }

  // Getters
  List<TimeSlot> get allSlots => List.unmodifiable(_slots);
  List<TimeSlot> get activeSlots =>
      _slots.where((s) => !s.isDeleted).toList(growable: false);
  List<MutationLogEntry> get mutationLogs =>
      List.unmodifiable(_mutationLogs);
  ClashReport get clashReport => _clashReport;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncStatusMessage => _lastSyncStatusMessage;

  int get pendingMutationCount =>
      _mutationLogs.where((m) => m.syncStatus == SyncStatus.pending).length;

  /// Initializes controller, loads persistent data from local storage,
  /// seeds initial timetable if first run, and runs clash detection.
  Future<void> initialize() async {
    _slots = _storage.loadSlots();
    _mutationLogs = _storage.loadMutationLogs();

    if (_slots.isEmpty && _storage.isFirstRun) {
      await _seedDefaultTimetable();
    }

    _recomputeClashes();
    notifyListeners();
  }

  /// Seeds realistic initial timetable with both clean and conflicting classes
  Future<void> _seedDefaultTimetable() async {
    final now = DateTime.now();
    final sampleSlots = [
      // Monday Clash Pair (30-min overlap)
      TimeSlot(
        id: 'slot-1',
        subject: 'Data Structures & Algorithms',
        day: 1, // Mon
        startMinutes: 540, // 09:00 AM
        endMinutes: 630,   // 10:30 AM
        room: 'Hall CS-101',
        instructor: 'Dr. Turing',
        colorValue: 0xFF1E88E5, // Blue
        updatedAt: now.subtract(const Duration(minutes: 50)),
        version: 1,
      ),
      TimeSlot(
        id: 'slot-2',
        subject: 'Database Systems',
        day: 1, // Mon
        startMinutes: 600, // 10:00 AM (Clashes with CS-101 10:00-10:30)
        endMinutes: 690,   // 11:30 AM
        room: 'Lab DB-202',
        instructor: 'Prof. Codd',
        colorValue: 0xFFFB8C00, // Orange
        updatedAt: now.subtract(const Duration(minutes: 45)),
        version: 1,
      ),

      // Tuesday Standalone Classes
      TimeSlot(
        id: 'slot-3',
        subject: 'Operating Systems',
        day: 2, // Tue
        startMinutes: 660, // 11:00 AM
        endMinutes: 750,   // 12:30 PM
        room: 'Hall OS-105',
        instructor: 'Prof. Tanenbaum',
        colorValue: 0xFF43A047, // Green
        updatedAt: now.subtract(const Duration(minutes: 40)),
        version: 1,
      ),
      TimeSlot(
        id: 'slot-4',
        subject: 'Computer Networks',
        day: 2, // Tue
        startMinutes: 840, // 02:00 PM
        endMinutes: 930,   // 03:30 PM
        room: 'Hall NET-301',
        instructor: 'Dr. Cerf',
        colorValue: 0xFF8E24AA, // Purple
        updatedAt: now.subtract(const Duration(minutes: 35)),
        version: 1,
      ),

      // Wednesday Contained Clash (AI inside longer workshop)
      TimeSlot(
        id: 'slot-5',
        subject: 'Artificial Intelligence',
        day: 3, // Wed
        startMinutes: 570, // 09:30 AM
        endMinutes: 660,   // 11:00 AM
        room: 'Lab AI-1',
        instructor: 'Dr. Hinton',
        colorValue: 0xFFE53935, // Red
        updatedAt: now.subtract(const Duration(minutes: 30)),
        version: 1,
      ),
      TimeSlot(
        id: 'slot-6',
        subject: 'Machine Learning Workshop',
        day: 3, // Wed
        startMinutes: 600, // 10:00 AM
        endMinutes: 720,   // 12:00 PM (Clashes 10:00 - 11:00)
        room: 'Auditorium 1',
        instructor: 'Dr. LeCun',
        colorValue: 0xFF00ACC1, // Cyan / Teal
        updatedAt: now.subtract(const Duration(minutes: 25)),
        version: 1,
      ),

      // Thursday Back-to-Back (Contiguous boundary check: 11:30 == 11:30, NO CLASH)
      TimeSlot(
        id: 'slot-7',
        subject: 'Software Engineering',
        day: 4, // Thu
        startMinutes: 600, // 10:00 AM
        endMinutes: 690,   // 11:30 AM
        room: 'Hall SE-204',
        instructor: 'Prof. Brooks',
        colorValue: 0xFF00897B, // Teal
        updatedAt: now.subtract(const Duration(minutes: 20)),
        version: 1,
      ),
      TimeSlot(
        id: 'slot-8',
        subject: 'Compiler Design',
        day: 4, // Thu
        startMinutes: 690, // 11:30 AM (Adjacent, no clash!)
        endMinutes: 780,   // 01:00 PM
        room: 'Hall COMP-4',
        instructor: 'Dr. Aho',
        colorValue: 0xFF5E35B1, // Deep Purple
        updatedAt: now.subtract(const Duration(minutes: 15)),
        version: 1,
      ),

      // Friday Double Clash
      TimeSlot(
        id: 'slot-9',
        subject: 'Cybersecurity & Crypto',
        day: 5, // Fri
        startMinutes: 780, // 01:00 PM
        endMinutes: 870,   // 02:30 PM
        room: 'Lab SEC-3',
        instructor: 'Dr. Rivest',
        colorValue: 0xFFD81B60, // Pink
        updatedAt: now.subtract(const Duration(minutes: 10)),
        version: 1,
      ),
      TimeSlot(
        id: 'slot-10',
        subject: 'Cloud Computing Systems',
        day: 5, // Fri
        startMinutes: 810, // 01:30 PM (Clashes with Cybersecurity 01:30-02:30)
        endMinutes: 900,   // 03:00 PM
        room: 'Room CLOUD-1',
        instructor: 'Dr. Dean',
        colorValue: 0xFF3949AB, // Indigo
        updatedAt: now.subtract(const Duration(minutes: 5)),
        version: 1,
      ),
    ];

    _slots = sampleSlots;
    await _storage.saveSlots(_slots);
    await _remoteServer.seedIfEmpty(_slots);
    await _storage.markInitialized();

    // Add initial log entries
    for (final slot in sampleSlots) {
      _mutationLogs.add(
        MutationLogEntry(
          logId: _uuid.v4(),
          timestamp: slot.updatedAt,
          action: MutationAction.create,
          entityId: slot.id,
          payload: slot.toJson(),
          syncStatus: SyncStatus.synced,
          syncedAt: slot.updatedAt,
        ),
      );
    }
    await _storage.saveMutationLogs(_mutationLogs);
  }

  void _recomputeClashes() {
    _clashReport = ClashDetector.computeClashReport(_slots);
  }

  /// Evaluates clash potential of a slot before saving (live preview in form)
  List<ClashDetail> previewClashes(TimeSlot candidate, {String? excludeSlotId}) {
    return ClashDetector.checkCandidateClashes(
      candidate,
      _slots,
      excludeSlotId: excludeSlotId,
    );
  }

  // ==========================================
  // Slot CRUD with Offline Logging & Live Clash
  // ==========================================

  Future<void> addSlot({
    required String subject,
    required int day,
    required int startMinutes,
    required int endMinutes,
    String room = '',
    String instructor = '',
    int colorValue = 0xFF1E88E5,
  }) async {
    final now = DateTime.now();
    final newSlot = TimeSlot(
      id: _uuid.v4(),
      subject: subject,
      day: day,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      room: room,
      instructor: instructor,
      colorValue: colorValue,
      updatedAt: now,
      version: 1,
    );

    // 1. Optimistic local state update
    _slots.add(newSlot);
    _recomputeClashes();

    // 2. Offline audit log entry
    final logEntry = MutationLogEntry(
      logId: _uuid.v4(),
      timestamp: now,
      action: MutationAction.create,
      entityId: newSlot.id,
      payload: newSlot.toJson(),
      syncStatus: SyncStatus.pending,
    );
    _mutationLogs.insert(0, logEntry);

    // 3. Persist locally to survive restart
    await _storage.saveSlots(_slots);
    await _storage.saveMutationLogs(_mutationLogs);
    notifyListeners();

    // 4. If online, trigger sync
    if (_isOnline) {
      await sync();
    }
  }

  Future<void> updateSlot(TimeSlot updatedSlot) async {
    final index = _slots.indexWhere((s) => s.id == updatedSlot.id);
    if (index < 0) return;

    final now = DateTime.now();
    final stampedSlot = updatedSlot.copyWith(
      updatedAt: now,
      version: _slots[index].version + 1,
    );

    // 1. Optimistic local update
    _slots[index] = stampedSlot;
    _recomputeClashes();

    // 2. Offline audit log entry
    final logEntry = MutationLogEntry(
      logId: _uuid.v4(),
      timestamp: now,
      action: MutationAction.update,
      entityId: stampedSlot.id,
      payload: stampedSlot.toJson(),
      syncStatus: SyncStatus.pending,
    );
    _mutationLogs.insert(0, logEntry);

    // 3. Persist locally
    await _storage.saveSlots(_slots);
    await _storage.saveMutationLogs(_mutationLogs);
    notifyListeners();

    // 4. Sync if online
    if (_isOnline) {
      await sync();
    }
  }

  Future<void> deleteSlot(String slotId) async {
    final index = _slots.indexWhere((s) => s.id == slotId);
    if (index < 0) return;

    final now = DateTime.now();
    final deletedSlot = _slots[index].copyWith(
      isDeleted: true,
      updatedAt: now,
      version: _slots[index].version + 1,
    );

    // 1. Mark as tombstone locally
    _slots[index] = deletedSlot;
    _recomputeClashes();

    // 2. Offline audit log entry
    final logEntry = MutationLogEntry(
      logId: _uuid.v4(),
      timestamp: now,
      action: MutationAction.delete,
      entityId: slotId,
      payload: deletedSlot.toJson(),
      syncStatus: SyncStatus.pending,
    );
    _mutationLogs.insert(0, logEntry);

    // 3. Persist locally
    await _storage.saveSlots(_slots);
    await _storage.saveMutationLogs(_mutationLogs);
    notifyListeners();

    // 4. Sync if online
    if (_isOnline) {
      await sync();
    }
  }

  // ==========================================
  // Online/Offline & Sync-on-Reconnect
  // ==========================================

  /// Toggles simulated network connectivity.
  /// When transitioning from false -> true, automatically triggers sync-on-reconnect.
  Future<void> setOnline(bool online) async {
    if (_isOnline == online) return;
    _isOnline = online;
    notifyListeners();

    if (_isOnline) {
      // Reconnected! Run automatic sync-on-reconnect
      await sync();
    }
  }

  /// Triggers full synchronization and reconciliation
  Future<void> sync() async {
    if (!_isOnline || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _syncService.synchronize(
        localSlots: _slots,
        mutationLogs: _mutationLogs,
      );

      _recomputeClashes();
      _lastSyncTime = DateTime.now();
      _lastSyncStatusMessage = result.message;
    } catch (e) {
      _lastSyncStatusMessage = 'Sync failed: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Simulates an external server modification (e.g. from another client/admin)
  /// to demonstrate conflict detection and reconciliation
  Future<void> injectRemoteServerConflict() async {
    await _remoteServer.injectExternalServerSlot(
      subject: 'Distributed Systems Seminar',
      day: 1, // Monday
      startMinutes: 570, // 09:30 AM (causes a 3-way clash with Data Structures & Databases!)
      endMinutes: 660,   // 11:00 AM
      room: 'Auditorium 2',
      instructor: 'Dr. Lamport',
      colorValue: 0xFFE91E63, // Pink
    );

    if (_isOnline) {
      // If currently online, immediately pull and reconcile
      await sync();
    } else {
      _lastSyncStatusMessage = 'External slot injected on server. Reconnect to pull and reconcile.';
      notifyListeners();
    }
  }

  /// Simulates restarting the application from disk without network
  Future<void> simulateAppRestart() async {
    _slots = _storage.loadSlots();
    _mutationLogs = _storage.loadMutationLogs();
    _recomputeClashes();
    _lastSyncStatusMessage = 'Simulated app restart: reloaded from disk persistence.';
    notifyListeners();
  }

  /// Resets everything to initial sample state
  Future<void> resetToSampleData() async {
    await _storage.clearAll();
    _slots.clear();
    _mutationLogs.clear();
    await _seedDefaultTimetable();
    _recomputeClashes();
    _lastSyncStatusMessage = 'Reset to sample timetable.';
    notifyListeners();
  }
}

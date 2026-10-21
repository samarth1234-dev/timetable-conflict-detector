import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_slot.dart';
import '../models/mutation_log.dart';

class StorageService {
  static const String _keySlots = 'tt_local_slots_v1';
  static const String _keyMutationLogs = 'tt_mutation_logs_v1';
  static const String _keyRemoteSlots = 'tt_remote_mock_slots_v1';
  static const String _keyInitialized = 'tt_is_initialized_v1';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get isFirstRun => !(_prefs.getBool(_keyInitialized) ?? false);

  Future<void> markInitialized() async {
    await _prefs.setBool(_keyInitialized, true);
  }

  Future<void> saveSlots(List<TimeSlot> slots) async {
    final jsonList = slots.map((s) => s.toJson()).toList();
    await _prefs.setString(_keySlots, jsonEncode(jsonList));
  }

  List<TimeSlot> loadSlots() {
    final raw = _prefs.getString(_keySlots);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => TimeSlot.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMutationLogs(List<MutationLogEntry> logs) async {
    final jsonList = logs.map((l) => l.toJson()).toList();
    await _prefs.setString(_keyMutationLogs, jsonEncode(jsonList));
  }

  List<MutationLogEntry> loadMutationLogs() {
    final raw = _prefs.getString(_keyMutationLogs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) =>
              MutationLogEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveRemoteSlots(List<TimeSlot> slots) async {
    final jsonList = slots.map((s) => s.toJson()).toList();
    await _prefs.setString(_keyRemoteSlots, jsonEncode(jsonList));
  }

  List<TimeSlot> loadRemoteSlots() {
    final raw = _prefs.getString(_keyRemoteSlots);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => TimeSlot.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearAll() async {
    await _prefs.remove(_keySlots);
    await _prefs.remove(_keyMutationLogs);
    await _prefs.remove(_keyRemoteSlots);
    await _prefs.remove(_keyInitialized);
  }
}

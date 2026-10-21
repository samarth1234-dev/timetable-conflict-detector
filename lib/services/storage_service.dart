import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_slot.dart';
import '../models/mutation_log.dart';

class StorageService {
  static const String _keySlots = 'tt_local_slots_v1';
  static const String _keyMutationLogs = 'tt_mutation_logs_v1';
  static const String _keyRemoteSlots = 'tt_remote_mock_slots_v1';
  static const String _keyInitialized = 'tt_is_initialized_v1';

  final SharedPreferences? _prefs;
  final Map<String, String> _memoryFallback = {};

  StorageService(this._prefs);

  static Future<StorageService> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return StorageService(prefs);
    } catch (e) {
      debugPrint('SharedPreferences init warning (using memory fallback): $e');
      return StorageService(null);
    }
  }

  bool get isFirstRun {
    if (_prefs == null) return !_memoryFallback.containsKey(_keyInitialized);
    return !(_prefs.getBool(_keyInitialized) ?? false);
  }

  Future<void> markInitialized() async {
    try {
      await _prefs?.setBool(_keyInitialized, true);
    } catch (e) {
      debugPrint('markInitialized warning: $e');
    }
    _memoryFallback[_keyInitialized] = 'true';
  }

  Future<void> saveSlots(List<TimeSlot> slots) async {
    final jsonList = slots.map((s) => s.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    try {
      await _prefs?.setString(_keySlots, jsonStr);
    } catch (e) {
      debugPrint('saveSlots warning: $e');
    }
    _memoryFallback[_keySlots] = jsonStr;
  }

  List<TimeSlot> loadSlots() {
    final raw = _prefs?.getString(_keySlots) ?? _memoryFallback[_keySlots];
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => TimeSlot.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('loadSlots parse warning: $e');
      return [];
    }
  }

  Future<void> saveMutationLogs(List<MutationLogEntry> logs) async {
    final jsonList = logs.map((l) => l.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    try {
      await _prefs?.setString(_keyMutationLogs, jsonStr);
    } catch (e) {
      debugPrint('saveMutationLogs warning: $e');
    }
    _memoryFallback[_keyMutationLogs] = jsonStr;
  }

  List<MutationLogEntry> loadMutationLogs() {
    final raw = _prefs?.getString(_keyMutationLogs) ?? _memoryFallback[_keyMutationLogs];
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) =>
              MutationLogEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('loadMutationLogs parse warning: $e');
      return [];
    }
  }

  Future<void> saveRemoteSlots(List<TimeSlot> slots) async {
    final jsonList = slots.map((s) => s.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    try {
      await _prefs?.setString(_keyRemoteSlots, jsonStr);
    } catch (e) {
      debugPrint('saveRemoteSlots warning: $e');
    }
    _memoryFallback[_keyRemoteSlots] = jsonStr;
  }

  List<TimeSlot> loadRemoteSlots() {
    final raw = _prefs?.getString(_keyRemoteSlots) ?? _memoryFallback[_keyRemoteSlots];
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => TimeSlot.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('loadRemoteSlots parse warning: $e');
      return [];
    }
  }

  Future<void> clearAll() async {
    try {
      await _prefs?.remove(_keySlots);
      await _prefs?.remove(_keyMutationLogs);
      await _prefs?.remove(_keyRemoteSlots);
      await _prefs?.remove(_keyInitialized);
    } catch (e) {
      debugPrint('clearAll warning: $e');
    }
    _memoryFallback.clear();
  }
}

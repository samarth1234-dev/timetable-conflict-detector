import 'dart:math' as math;
import '../models/time_slot.dart';
import '../models/clash_result.dart';

class ClashDetector {
  /// Checks whether two slots overlap in time.
  /// 
  /// Interval Comparison Logic:
  /// Two half-open intervals [A.start, A.end) and [B.start, B.end) on the same day
  /// overlap if and only if:
  ///   max(A.start, B.start) < min(A.end, B.end)
  /// 
  /// Notice that if A.end == B.start, overlap is 0 (contiguous classes, NOT a clash).
  static bool doSlotsOverlap(TimeSlot a, TimeSlot b) {
    if (a.day != b.day) return false;
    if (a.isDeleted || b.isDeleted) return false;
    if (a.id == b.id) return false;

    final overlapStart = math.max(a.startMinutes, b.startMinutes);
    final overlapEnd = math.min(a.endMinutes, b.endMinutes);

    return overlapStart < overlapEnd;
  }

  /// Calculates the exact overlap duration and interval between two slots.
  /// Returns null if they do not overlap.
  static ClashDetail? calculateOverlapDetail(TimeSlot target, TimeSlot other) {
    if (!doSlotsOverlap(target, other)) return null;

    final overlapStart = math.max(target.startMinutes, other.startMinutes);
    final overlapEnd = math.min(target.endMinutes, other.endMinutes);
    final overlapDuration = overlapEnd - overlapStart;

    if (overlapDuration <= 0) return null;

    return ClashDetail(
      conflictingSlot: other,
      overlapStartMinutes: overlapStart,
      overlapEndMinutes: overlapEnd,
      overlapMinutes: overlapDuration,
    );
  }

  /// Computes a full clash report across all active slots in the timetable.
  /// 
  /// Complexity: O(D * (N_d log N_d + K_d)) where D is number of days (<=7),
  /// N_d is slots on day d, and K_d is the number of overlapping pairs on day d.
  static ClashReport computeClashReport(List<TimeSlot> allSlots) {
    final activeSlots = allSlots.where((s) => !s.isDeleted).toList();

    // Group active slots by day
    final Map<int, List<TimeSlot>> slotsByDay = {};
    for (final slot in activeSlots) {
      slotsByDay.putIfAbsent(slot.day, () => []).add(slot);
    }

    final Set<String> clashingSlotIds = {};
    final Map<String, List<ClashDetail>> detailsBySlotId = {};
    final List<ClashPair> clashPairs = [];

    // Evaluate collisions day-by-day
    for (final entry in slotsByDay.entries) {
      final daySlots = entry.value;
      // Sort slots by startMinutes ascending, then endMinutes
      daySlots.sort((a, b) {
        final startComp = a.startMinutes.compareTo(b.startMinutes);
        if (startComp != 0) return startComp;
        return a.endMinutes.compareTo(b.endMinutes);
      });

      for (int i = 0; i < daySlots.length; i++) {
        final slotA = daySlots[i];
        for (int j = i + 1; j < daySlots.length; j++) {
          final slotB = daySlots[j];

          // Because daySlots is sorted by startMinutes:
          // If slotB starts at or after slotA ends, then no subsequent slot in
          // daySlots can overlap with slotA either! We can break early.
          if (slotB.startMinutes >= slotA.endMinutes) {
            break;
          }

          // Overlap detected!
          final overlapStart = math.max(slotA.startMinutes, slotB.startMinutes);
          final overlapEnd = math.min(slotA.endMinutes, slotB.endMinutes);
          final overlapDuration = overlapEnd - overlapStart;

          if (overlapDuration > 0) {
            clashingSlotIds.add(slotA.id);
            clashingSlotIds.add(slotB.id);

            // Add detail for slotA
            detailsBySlotId.putIfAbsent(slotA.id, () => []).add(
                  ClashDetail(
                    conflictingSlot: slotB,
                    overlapStartMinutes: overlapStart,
                    overlapEndMinutes: overlapEnd,
                    overlapMinutes: overlapDuration,
                  ),
                );

            // Add detail for slotB
            detailsBySlotId.putIfAbsent(slotB.id, () => []).add(
                  ClashDetail(
                    conflictingSlot: slotA,
                    overlapStartMinutes: overlapStart,
                    overlapEndMinutes: overlapEnd,
                    overlapMinutes: overlapDuration,
                  ),
                );

            // Record unique clash pair
            clashPairs.add(
              ClashPair(
                slotA: slotA,
                slotB: slotB,
                overlapStartMinutes: overlapStart,
                overlapEndMinutes: overlapEnd,
                overlapMinutes: overlapDuration,
              ),
            );
          }
        }
      }
    }

    return ClashReport(
      clashingSlotIds: clashingSlotIds,
      detailsBySlotId: detailsBySlotId,
      clashPairs: clashPairs,
    );
  }

  /// Interactive check for a candidate slot against existing timetable slots.
  /// 
  /// Returns all clashes that the candidate would cause if added or updated.
  /// Used for live real-time clash feedback while typing/adjusting times in the form.
  static List<ClashDetail> checkCandidateClashes(
    TimeSlot candidate,
    List<TimeSlot> existingSlots, {
    String? excludeSlotId,
  }) {
    final List<ClashDetail> candidateClashes = [];

    for (final other in existingSlots) {
      if (other.isDeleted) continue;
      if (excludeSlotId != null && other.id == excludeSlotId) continue;
      if (other.id == candidate.id) continue;
      if (other.day != candidate.day) continue;

      final detail = calculateOverlapDetail(candidate, other);
      if (detail != null) {
        candidateClashes.add(detail);
      }
    }

    // Sort by overlap start time
    candidateClashes.sort(
      (a, b) => a.overlapStartMinutes.compareTo(b.overlapStartMinutes),
    );

    return candidateClashes;
  }
}

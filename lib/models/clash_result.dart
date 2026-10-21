import 'package:flutter/foundation.dart';
import 'time_slot.dart';

@immutable
class ClashDetail {
  final TimeSlot conflictingSlot;
  final int overlapStartMinutes;
  final int overlapEndMinutes;
  final int overlapMinutes;

  const ClashDetail({
    required this.conflictingSlot,
    required this.overlapStartMinutes,
    required this.overlapEndMinutes,
    required this.overlapMinutes,
  });

  String get overlapTimeRangeFormatted =>
      '${TimeSlot.minutesTo12HourString(overlapStartMinutes)} - ${TimeSlot.minutesTo12HourString(overlapEndMinutes)}';

  String get summary =>
      '${conflictingSlot.subject} ($overlapMinutes min overlap: $overlapTimeRangeFormatted)';
}

@immutable
class ClashPair {
  final TimeSlot slotA;
  final TimeSlot slotB;
  final int overlapStartMinutes;
  final int overlapEndMinutes;
  final int overlapMinutes;

  const ClashPair({
    required this.slotA,
    required this.slotB,
    required this.overlapStartMinutes,
    required this.overlapEndMinutes,
    required this.overlapMinutes,
  });

  String get overlapTimeRangeFormatted =>
      '${TimeSlot.minutesTo12HourString(overlapStartMinutes)} - ${TimeSlot.minutesTo12HourString(overlapEndMinutes)}';

  String get formattedSummary =>
      '${slotA.subject} (${slotA.militaryTimeRange}) ⚔️ ${slotB.subject} (${slotB.militaryTimeRange}) [${slotA.shortDayName}]';
}

@immutable
class ClashReport {
  final Set<String> clashingSlotIds;
  final Map<String, List<ClashDetail>> detailsBySlotId;
  final List<ClashPair> clashPairs;

  const ClashReport({
    required this.clashingSlotIds,
    required this.detailsBySlotId,
    required this.clashPairs,
  });

  bool hasClash(String slotId) => clashingSlotIds.contains(slotId);

  List<ClashDetail> getClashesFor(String slotId) =>
      detailsBySlotId[slotId] ?? const [];

  int get totalConflictPairs => clashPairs.length;

  bool get isEmpty => clashingSlotIds.isEmpty;
  bool get isNotEmpty => clashingSlotIds.isNotEmpty;

  static const ClashReport empty = ClashReport(
    clashingSlotIds: {},
    detailsBySlotId: {},
    clashPairs: [],
  );
}

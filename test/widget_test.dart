import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_conflict_detector/models/time_slot.dart';
import 'package:timetable_conflict_detector/models/mutation_log.dart';
import 'package:timetable_conflict_detector/services/clash_detector.dart';

void main() {
  group('Interval Comparison & Clash Detection Logic', () {
    test('Detects partial overlap on the same day', () {
      final slotA = TimeSlot(
        id: 'slot-a',
        subject: 'Algorithms',
        day: 1, // Monday
        startMinutes: 540, // 09:00 AM
        endMinutes: 630,   // 10:30 AM
        updatedAt: DateTime.now(),
      );

      final slotB = TimeSlot(
        id: 'slot-b',
        subject: 'Databases',
        day: 1, // Monday
        startMinutes: 600, // 10:00 AM (Clashes 10:00 - 10:30)
        endMinutes: 690,   // 11:30 AM
        updatedAt: DateTime.now(),
      );

      expect(ClashDetector.doSlotsOverlap(slotA, slotB), isTrue);

      final detail = ClashDetector.calculateOverlapDetail(slotA, slotB);
      expect(detail, isNotNull);
      expect(detail!.overlapMinutes, equals(30));
      expect(detail.overlapStartMinutes, equals(600));
      expect(detail.overlapEndMinutes, equals(630));
    });

    test('Boundary Condition: Adjacent / contiguous classes do NOT clash', () {
      final class1 = TimeSlot(
        id: 'c1',
        subject: 'Physics',
        day: 2, // Tuesday
        startMinutes: 600, // 10:00 AM
        endMinutes: 690,   // 11:30 AM
        updatedAt: DateTime.now(),
      );

      final class2 = TimeSlot(
        id: 'c2',
        subject: 'Chemistry',
        day: 2, // Tuesday
        startMinutes: 690, // 11:30 AM (Immediately follows class 1)
        endMinutes: 780,   // 01:00 PM
        updatedAt: DateTime.now(),
      );

      expect(ClashDetector.doSlotsOverlap(class1, class2), isFalse);
      final detail = ClashDetector.calculateOverlapDetail(class1, class2);
      expect(detail, isNull);
    });

    test('Detects complete containment (A inside B)', () {
      final longLab = TimeSlot(
        id: 'lab',
        subject: 'Robotics Workshop',
        day: 3, // Wednesday
        startMinutes: 600, // 10:00 AM
        endMinutes: 840,   // 02:00 PM (4 hours)
        updatedAt: DateTime.now(),
      );

      final shortQuiz = TimeSlot(
        id: 'quiz',
        subject: 'Math Quiz',
        day: 3, // Wednesday
        startMinutes: 660, // 11:00 AM
        endMinutes: 720,   // 12:00 PM (1 hour inside lab)
        updatedAt: DateTime.now(),
      );

      expect(ClashDetector.doSlotsOverlap(longLab, shortQuiz), isTrue);
      final detail = ClashDetector.calculateOverlapDetail(longLab, shortQuiz);
      expect(detail!.overlapMinutes, equals(60));
      expect(detail.overlapStartMinutes, equals(660));
      expect(detail.overlapEndMinutes, equals(720));
    });

    test('Same time range on different days does NOT clash', () {
      final mondayClass = TimeSlot(
        id: 'mon',
        subject: 'History',
        day: 1, // Monday
        startMinutes: 600,
        endMinutes: 690,
        updatedAt: DateTime.now(),
      );

      final tuesdayClass = TimeSlot(
        id: 'tue',
        subject: 'History',
        day: 2, // Tuesday
        startMinutes: 600,
        endMinutes: 690,
        updatedAt: DateTime.now(),
      );

      expect(ClashDetector.doSlotsOverlap(mondayClass, tuesdayClass), isFalse);
    });

    test('Candidate clash preview detects collisions before saving', () {
      final existing = [
        TimeSlot(
          id: 'ex-1',
          subject: 'Computer Networks',
          day: 4, // Thursday
          startMinutes: 600, // 10:00 AM
          endMinutes: 720,   // 12:00 PM
          updatedAt: DateTime.now(),
        ),
      ];

      final candidate = TimeSlot(
        id: 'cand',
        subject: 'Operating Systems',
        day: 4, // Thursday
        startMinutes: 660, // 11:00 AM
        endMinutes: 780,   // 01:00 PM
        updatedAt: DateTime.now(),
      );

      final clashes = ClashDetector.checkCandidateClashes(candidate, existing);
      expect(clashes.length, equals(1));
      expect(clashes.first.conflictingSlot.subject, equals('Computer Networks'));
      expect(clashes.first.overlapMinutes, equals(60));
    });
  });

  group('Offline Mutation Log & Data Structure', () {
    test('TimeSlot JSON serialization round-trip', () {
      final slot = TimeSlot(
        id: 'test-uuid-1234',
        subject: 'Artificial Intelligence',
        day: 5,
        startMinutes: 840,
        endMinutes: 930,
        room: 'Lab AI-3',
        instructor: 'Dr. Turing',
        colorValue: 0xFF1E88E5,
        updatedAt: DateTime(2026, 10, 21, 10, 30),
        version: 2,
        isDeleted: false,
      );

      final json = slot.toJson();
      final revived = TimeSlot.fromJson(json);

      expect(revived.id, equals(slot.id));
      expect(revived.subject, equals(slot.subject));
      expect(revived.day, equals(slot.day));
      expect(revived.startMinutes, equals(slot.startMinutes));
      expect(revived.endMinutes, equals(slot.endMinutes));
      expect(revived.room, equals(slot.room));
      expect(revived.instructor, equals(slot.instructor));
      expect(revived.colorValue, equals(slot.colorValue));
      expect(revived.version, equals(2));
    });

    test('MutationLogEntry JSON serialization and pending status', () {
      final log = MutationLogEntry(
        logId: 'log-uuid-999',
        timestamp: DateTime(2026, 10, 21, 14, 0),
        action: MutationAction.create,
        entityId: 'test-slot-1',
        payload: {
          'id': 'test-slot-1',
          'subject': 'Software Engineering',
          'day': 3,
        },
        syncStatus: SyncStatus.pending,
      );

      final json = log.toJson();
      final revived = MutationLogEntry.fromJson(json);

      expect(revived.logId, equals(log.logId));
      expect(revived.action, equals(MutationAction.create));
      expect(revived.entityId, equals('test-slot-1'));
      expect(revived.syncStatus, equals(SyncStatus.pending));
    });
  });
}

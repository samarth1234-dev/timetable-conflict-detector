import 'package:flutter/material.dart';

class TimeSlot {
  final String id;
  final String subject;
  final int day; // 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
  final int startMinutes; // Minutes from 00:00 (e.g., 9:00 AM = 540)
  final int endMinutes;   // Minutes from 00:00 (e.g., 10:30 AM = 630)
  final String room;
  final String instructor;
  final int colorValue;
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;

  const TimeSlot({
    required this.id,
    required this.subject,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    this.room = '',
    this.instructor = '',
    this.colorValue = 0xFF3F51B5, // Default indigo
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
  });

  int get durationMinutes => endMinutes - startMinutes;

  String get dayName {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Day $day';
    }
  }

  String get shortDayName {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return 'D$day';
    }
  }

  static String minutesToTimeString(int totalMinutes) {
    final hours = (totalMinutes ~/ 60) % 24;
    final minutes = totalMinutes % 60;
    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  static String minutesTo12HourString(int totalMinutes) {
    final hours = (totalMinutes ~/ 60) % 24;
    final minutes = totalMinutes % 60;
    final period = hours >= 12 ? 'PM' : 'AM';
    final h12 = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours);
    final mStr = minutes.toString().padLeft(2, '0');
    return '$h12:$mStr $period';
  }

  String get startTimeFormatted => minutesTo12HourString(startMinutes);
  String get endTimeFormatted => minutesTo12HourString(endMinutes);
  String get timeRangeFormatted => '$startTimeFormatted - $endTimeFormatted';
  String get militaryTimeRange => '${minutesToTimeString(startMinutes)} - ${minutesToTimeString(endMinutes)}';

  Color get color => Color(colorValue);

  TimeSlot copyWith({
    String? id,
    String? subject,
    int? day,
    int? startMinutes,
    int? endMinutes,
    String? room,
    String? instructor,
    int? colorValue,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      day: day ?? this.day,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      colorValue: colorValue ?? this.colorValue,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'day': day,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'room': room,
      'instructor': instructor,
      'colorValue': colorValue,
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
      'isDeleted': isDeleted,
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String,
      subject: json['subject'] as String,
      day: json['day'] as int,
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
      room: (json['room'] as String?) ?? '',
      instructor: (json['instructor'] as String?) ?? '',
      colorValue: (json['colorValue'] as int?) ?? 0xFF3F51B5,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: (json['version'] as int?) ?? 1,
      isDeleted: (json['isDeleted'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => id.hashCode ^ version.hashCode ^ updatedAt.hashCode;
}

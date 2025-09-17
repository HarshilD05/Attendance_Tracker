import 'package:cloud_firestore/cloud_firestore.dart';

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday;

  String get displayName {
    switch (this) {
      case WeekDay.monday:
        return 'Monday';
      case WeekDay.tuesday:
        return 'Tuesday';
      case WeekDay.wednesday:
        return 'Wednesday';
      case WeekDay.thursday:
        return 'Thursday';
      case WeekDay.friday:
        return 'Friday';
      case WeekDay.saturday:
        return 'Saturday';
    }
  }
}

class TimeSlot {
  final String subjectId;
  final String startTime; // Format: "HH:mm"
  final String endTime;   // Format: "HH:mm"
  final String? room;

  TimeSlot({
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      subjectId: json['subjectId'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      room: json['room'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
    };
  }

  TimeSlot copyWith({
    String? subjectId,
    String? startTime,
    String? endTime,
    String? room,
  }) {
    return TimeSlot(
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
    );
  }

  // Helper method to check if this slot overlaps with another
  bool overlapsWith(TimeSlot other) {
    final thisStart = _timeToMinutes(startTime);
    final thisEnd = _timeToMinutes(endTime);
    final otherStart = _timeToMinutes(other.startTime);
    final otherEnd = _timeToMinutes(other.endTime);
    
    return (thisStart < otherEnd && thisEnd > otherStart);
  }

  // Helper method to convert time string to minutes
  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  // Helper method to format time for display
  String get formattedTimeRange => '$startTime - $endTime';

  @override
  String toString() {
    return 'TimeSlot(subjectId: $subjectId, startTime: $startTime, endTime: $endTime, room: $room)';
  }
}

class TimeTable {
  final String id;
  final Map<WeekDay, List<TimeSlot>> schedule;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeTable({
    required this.id,
    required this.schedule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimeTable.empty(String id) {
    final now = DateTime.now();
    return TimeTable(
      id: id,
      schedule: {
        for (var day in WeekDay.values) day: <TimeSlot>[]
      },
      createdAt: now,
      updatedAt: now,
    );
  }

  factory TimeTable.fromJson(Map<String, dynamic> json) {
    final scheduleMap = json['schedule'] as Map<String, dynamic>;
    final schedule = <WeekDay, List<TimeSlot>>{};
    
    for (var day in WeekDay.values) {
      final daySlots = scheduleMap[day.name] as List<dynamic>? ?? [];
      schedule[day] = daySlots
          .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
          .toList();
    }

    return TimeTable(
      id: json['id'] as String,
      schedule: schedule,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    final scheduleJson = <String, dynamic>{};
    
    for (var entry in schedule.entries) {
      scheduleJson[entry.key.name] = entry.value
          .map((slot) => slot.toJson())
          .toList();
    }

    return {
      'id': id,
      'schedule': scheduleJson,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TimeTable.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeTable.fromJson({...data, 'id': doc.id});
  }

  TimeTable copyWith({
    String? id,
    Map<WeekDay, List<TimeSlot>>? schedule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeTable(
      id: id ?? this.id,
      schedule: schedule ?? Map.from(this.schedule),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Get total lectures per week for a subject
  int getTotalLecturesPerWeek(String subjectId) {
    int total = 0;
    for (var daySlots in schedule.values) {
      total += daySlots.where((slot) => slot.subjectId == subjectId).length;
    }
    return total;
  }

  @override
  String toString() {
    return 'TimeTable(id: $id, schedule: $schedule)';
  }
}

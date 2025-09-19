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
    final thisStart = TimeSlot.timeToMinutes(startTime);
    final thisEnd = TimeSlot.timeToMinutes(endTime);
    final otherStart = TimeSlot.timeToMinutes(other.startTime);
    final otherEnd = TimeSlot.timeToMinutes(other.endTime);
    
    return (thisStart < otherEnd && thisEnd > otherStart);
  }

  // Helper method to convert time string to minutes
  static int timeToMinutes(String time) {
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

class DaySchedule {
  final WeekDay day;
  final List<TimeSlot> timeSlots;
  final DateTime createdAt;
  final DateTime updatedAt;

  DaySchedule({
    required this.day,
    required this.timeSlots,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DaySchedule.empty(WeekDay day) {
    final now = DateTime.now();
    return DaySchedule(
      day: day,
      timeSlots: <TimeSlot>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DaySchedule.fromJson(Map<String, dynamic> json, WeekDay day) {
    final slotsJson = json['timeSlots'] as List<dynamic>? ?? [];
    final timeSlots = slotsJson
        .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
        .toList();

    // Sort time slots by start time
    timeSlots.sort((a, b) {
      final aMinutes = TimeSlot.timeToMinutes(a.startTime);
      final bMinutes = TimeSlot.timeToMinutes(b.startTime);
      return aMinutes.compareTo(bMinutes);
    });

    return DaySchedule(
      day: day,
      timeSlots: timeSlots,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    // Sort time slots by start time before storing
    final sortedSlots = List<TimeSlot>.from(timeSlots);
    sortedSlots.sort((a, b) {
      final aMinutes = TimeSlot.timeToMinutes(a.startTime);
      final bMinutes = TimeSlot.timeToMinutes(b.startTime);
      return aMinutes.compareTo(bMinutes);
    });

    return {
      'day': day.name,
      'timeSlots': sortedSlots.map((slot) => slot.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DaySchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dayName = doc.id; // Document ID will be the day name
    final day = WeekDay.values.firstWhere(
      (d) => d.name == dayName,
      orElse: () => WeekDay.monday,
    );
    return DaySchedule.fromJson(data, day);
  }

  DaySchedule copyWith({
    WeekDay? day,
    List<TimeSlot>? timeSlots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DaySchedule(
      day: day ?? this.day,
      timeSlots: timeSlots ?? List.from(this.timeSlots),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Add a time slot and maintain sorting
  DaySchedule addTimeSlot(TimeSlot slot) {
    final newSlots = List<TimeSlot>.from(timeSlots);
    newSlots.add(slot);
    newSlots.sort((a, b) {
      final aMinutes = TimeSlot.timeToMinutes(a.startTime);
      final bMinutes = TimeSlot.timeToMinutes(b.startTime);
      return aMinutes.compareTo(bMinutes);
    });
    
    return copyWith(timeSlots: newSlots);
  }

  // Remove a time slot by subject ID and time
  DaySchedule removeTimeSlot(String subjectId, String startTime) {
    final newSlots = timeSlots
        .where((slot) => !(slot.subjectId == subjectId && slot.startTime == startTime))
        .toList();
    
    return copyWith(timeSlots: newSlots);
  }

  // Check if there are any time conflicts with a new slot
  bool hasTimeConflict(TimeSlot newSlot) {
    return timeSlots.any((slot) => slot.overlapsWith(newSlot));
  }

  @override
  String toString() {
    return 'DaySchedule(day: $day, timeSlots: $timeSlots)';
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

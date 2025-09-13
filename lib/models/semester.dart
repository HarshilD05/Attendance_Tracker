import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject.dart';
import 'timetable.dart';

class Semester {
  final String? id;
  final String name;
  final DateTime semStartDate;
  final DateTime semEndDate;
  final List<DateTime> holidayList;
  final List<Subject> subjectList;
  final TimeTable? timeTable;
  final String userId; // Firebase Auth user ID
  final DateTime createdAt;
  final DateTime updatedAt;

  Semester({
    this.id,
    required this.name,
    required this.semStartDate,
    required this.semEndDate,
    required this.holidayList,
    required this.subjectList,
    this.timeTable,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Semester.create({
    required String name,
    required DateTime semStartDate,
    required DateTime semEndDate,
    required String userId,
  }) {
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Generate default holidays (all Sundays between start and end date)
    final defaultHolidays = _generateDefaultHolidays(semStartDate, semEndDate);
    
    return Semester(
      id: null, // Will be set by Firestore
      name: name,
      semStartDate: semStartDate,
      semEndDate: semEndDate,
      holidayList: defaultHolidays,
      subjectList: [],
      timeTable: TimeTable.empty(id),
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Generate default holidays (all Sundays)
  static List<DateTime> _generateDefaultHolidays(DateTime startDate, DateTime endDate) {
    final holidays = <DateTime>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (current.weekday == DateTime.sunday) {
        holidays.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    
    return holidays;
  }

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as String?,
      name: json['name'] as String,
      semStartDate: (json['semStartDate'] as Timestamp).toDate(),
      semEndDate: (json['semEndDate'] as Timestamp).toDate(),
      holidayList: (json['holidayList'] as List<dynamic>)
          .map((timestamp) => (timestamp as Timestamp).toDate())
          .toList(),
      subjectList: (json['subjectList'] as List<dynamic>)
          .map((subject) => Subject.fromJson(subject as Map<String, dynamic>))
          .toList(),
      timeTable: json['timeTable'] != null
          ? TimeTable.fromJson(json['timeTable'] as Map<String, dynamic>)
          : null,
      userId: json['userId'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'semStartDate': Timestamp.fromDate(semStartDate),
      'semEndDate': Timestamp.fromDate(semEndDate),
      'holidayList': holidayList.map((date) => Timestamp.fromDate(date)).toList(),
      'subjectList': subjectList.map((subject) => subject.toJson()).toList(),
      'timeTable': timeTable?.toJson(),
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Semester.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Semester.fromJson({...data, 'id': doc.id});
  }

  Semester copyWith({
    String? id,
    String? name,
    DateTime? semStartDate,
    DateTime? semEndDate,
    List<DateTime>? holidayList,
    List<Subject>? subjectList,
    TimeTable? timeTable,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      semStartDate: semStartDate ?? this.semStartDate,
      semEndDate: semEndDate ?? this.semEndDate,
      holidayList: holidayList ?? List.from(this.holidayList),
      subjectList: subjectList ?? List.from(this.subjectList),
      timeTable: timeTable ?? this.timeTable,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Calculate total working days (excluding holidays and sundays)
  int get totalWorkingDays {
    var workingDays = 0;
    var current = DateTime(semStartDate.year, semStartDate.month, semStartDate.day);
    
    while (current.isBefore(semEndDate) || current.isAtSameMomentAs(semEndDate)) {
      if (current.weekday != DateTime.sunday && 
          !holidayList.any((holiday) => 
            holiday.year == current.year && 
            holiday.month == current.month && 
            holiday.day == current.day)) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return workingDays;
  }

  // Calculate total lectures for a subject throughout the semester
  int getTotalLecturesForSubject(String subjectId) {
    if (timeTable == null) return 0;
    
    final lecturesPerWeek = timeTable!.getTotalLecturesPerWeek(subjectId);
    final totalWeeks = (semEndDate.difference(semStartDate).inDays / 7).ceil();
    
    return lecturesPerWeek * totalWeeks;
  }

  // Get semester duration in days
  int get durationInDays {
    return semEndDate.difference(semStartDate).inDays + 1;
  }

  // Check if semester is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(semStartDate) && now.isBefore(semEndDate);
  }

  @override
  String toString() {
    return 'Semester(id: $id, name: $name, startDate: $semStartDate, endDate: $semEndDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Semester && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Semester {
  final String? id;
  final String name;
  final DateTime semStartDate;
  final DateTime semEndDate;
  final List<DateTime> holidayList;
  final String userId; // Firebase Auth user ID
  final DateTime createdAt;
  final DateTime updatedAt;

  Semester({
    this.id,
    required this.name,
    required this.semStartDate,
    required this.semEndDate,
    required this.holidayList,
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
    
    // Generate default holidays (all Sundays between start and end date)
    final defaultHolidays = _generateDefaultHolidays(semStartDate, semEndDate);
    
    return Semester(
      id: null, // Will be set by Firestore
      name: name,
      semStartDate: semStartDate,
      semEndDate: semEndDate,
      holidayList: defaultHolidays,
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

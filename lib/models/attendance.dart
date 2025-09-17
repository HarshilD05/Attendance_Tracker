import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String subjectId;
  final DateTime date;
  final bool present;
  final String? timeSlot; // e.g., "09:00-10:00"
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.present,
    this.timeSlot,
    required this.createdAt,
  });

  // Factory constructor from JSON
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      present: json['present'] as bool,
      timeSlot: json['timeSlot'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'date': Timestamp.fromDate(date),
      'present': present,
      'timeSlot': timeSlot,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Factory constructor from Firestore document
  factory Attendance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Attendance.fromJson({...data, 'id': doc.id});
  }

  // Copy with method for updates
  Attendance copyWith({
    String? id,
    String? subjectId,
    DateTime? date,
    bool? present,
    String? timeSlot,
    DateTime? createdAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      present: present ?? this.present,
      timeSlot: timeSlot ?? this.timeSlot,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Attendance(id: $id, subjectId: $subjectId, date: $date, present: $present, timeSlot: $timeSlot)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
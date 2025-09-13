import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String subjectName;
  final String? teacherName;
  final int attendanceCredits;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.subjectName,
    this.teacherName,
    required this.attendanceCredits,
    required this.createdAt,
  });

  // Factory constructor from JSON
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      subjectName: json['subjectName'] as String,
      teacherName: json['teacherName'] as String?,
      attendanceCredits: json['attendanceCredits'] as int,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectName': subjectName,
      'teacherName': teacherName,
      'attendanceCredits': attendanceCredits,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Factory constructor from Firestore document
  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject.fromJson({...data, 'id': doc.id});
  }

  // Copy with method for updates
  Subject copyWith({
    String? id,
    String? subjectName,
    String? teacherName,
    int? attendanceCredits,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      teacherName: teacherName ?? this.teacherName,
      attendanceCredits: attendanceCredits ?? this.attendanceCredits,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Subject(id: $id, subjectName: $subjectName, teacherName: $teacherName, attendanceCredits: $attendanceCredits)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

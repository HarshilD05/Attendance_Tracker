class Subject {
  final int? id;
  final int semId;
  final String name;
  final String? teacher; // Optional
  final double minAttendanceReq;

  Subject({
    this.id,
    required this.semId,
    required this.name,
    this.teacher,
    required this.minAttendanceReq,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sem_id': semId,
      'name': name,
      'teacher': teacher,
      'min_attendance_req': minAttendanceReq,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      semId: map['sem_id'] as int,
      name: map['name'] as String,
      teacher: map['teacher'] as String?,
      minAttendanceReq: (map['min_attendance_req'] as num).toDouble(),
    );
  }
}

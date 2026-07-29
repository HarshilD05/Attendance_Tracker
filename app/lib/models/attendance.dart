class Attendance {
  final int? id;
  final int semId;
  final int subId;
  final int? slotId;
  final String date;
  final String lecStatus; // 'Conducted' | 'Cancelled'
  final String studentStatus; // 'Present' | 'Absent' | 'Late'

  Attendance({
    this.id,
    required this.semId,
    required this.subId,
    this.slotId,
    required this.date,
    required this.lecStatus,
    required this.studentStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sem_id': semId,
      'sub_id': subId,
      'slot_id': slotId,
      'date': date,
      'lec_status': lecStatus,
      'student_status': studentStatus,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int?,
      semId: map['sem_id'] as int,
      subId: map['sub_id'] as int,
      slotId: map['slot_id'] as int?,
      date: map['date'] as String,
      lecStatus: map['lec_status'] as String,
      studentStatus: map['student_status'] as String,
    );
  }
}

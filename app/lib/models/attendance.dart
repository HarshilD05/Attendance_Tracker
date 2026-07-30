class Attendance {
  final int? id;
  final int semId;
  final int subId;
  final int? slotId;
  final String date;
  final int isCancelled; // 0 = false, 1 = true
  final String studentStatus; // 'P' | 'A' | 'U'

  Attendance({
    this.id,
    required this.semId,
    required this.subId,
    this.slotId,
    required this.date,
    required this.isCancelled,
    required this.studentStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sem_id': semId,
      'sub_id': subId,
      'slot_id': slotId,
      'date': date,
      'is_cancelled': isCancelled,
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
      isCancelled: map['is_cancelled'] as int,
      studentStatus: map['student_status'] as String,
    );
  }
}

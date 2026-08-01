class ExtraLec {
  final int? id;
  final int semId;
  final int subId;
  final String date;
  final String startTime;
  final String endTime;
  final String classRoom;

  ExtraLec({
    this.id,
    required this.semId,
    required this.subId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.classRoom,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sem_id': semId,
      'sub_id': subId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'class_room': classRoom,
    };
  }

  factory ExtraLec.fromMap(Map<String, dynamic> map) {
    return ExtraLec(
      id: map['id'] as int?,
      semId: map['sem_id'] as int,
      subId: map['sub_id'] as int,
      date: map['date'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      classRoom: map['class_room'] as String? ?? '',
    );
  }
}

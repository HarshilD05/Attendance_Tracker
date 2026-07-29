class TimetableSlot {
  final int? slotId;
  final int semId;
  final int subId;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime;
  final String endTime;
  final String classRoom;

  TimetableSlot({
    this.slotId,
    required this.semId,
    required this.subId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.classRoom,
  });

  Map<String, dynamic> toMap() {
    return {
      'slot_id': slotId,
      'sem_id': semId,
      'sub_id': subId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'class_room': classRoom,
    };
  }

  factory TimetableSlot.fromMap(Map<String, dynamic> map) {
    return TimetableSlot(
      slotId: map['slot_id'] as int?,
      semId: map['sem_id'] as int,
      subId: map['sub_id'] as int,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      classRoom: map['class_room'] as String,
    );
  }
}

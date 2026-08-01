class TimetableSlot {
  final int? slotId;
  final int? extraLecId; // New: for extra lec slots
  final int semId;
  final int subId;
  final int dayOfWeek; // 1-7, or 0 for extra lec
  final String startTime;
  final String endTime;
  final String classRoom;
  final String? specificDate; // Keep this so UI knows it's extra lec if specificDate != null

  TimetableSlot({
    this.slotId,
    this.extraLecId,
    required this.semId,
    required this.subId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.classRoom,
    this.specificDate,
  });

  bool get isExtraLec => extraLecId != null || specificDate != null;

  Map<String, dynamic> toMap() {
    return {
      'slot_id': slotId,
      'extra_lec_id': extraLecId,
      'sem_id': semId,
      'sub_id': subId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'class_room': classRoom,
      'specific_date': specificDate,
    };
  }

  factory TimetableSlot.fromMap(Map<String, dynamic> map) {
    return TimetableSlot(
      slotId: map['slot_id'] as int?,
      extraLecId: map['extra_lec_id'] as int?, // Read from union query
      semId: map['sem_id'] as int,
      subId: map['sub_id'] as int,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      classRoom: map['class_room'] as String? ?? '',
      specificDate: map['specific_date'] as String?, // Read from union query
    );
  }
}

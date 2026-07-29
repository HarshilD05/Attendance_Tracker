class Semester {
  final int? id;
  final String name;
  final String startDate;
  final String endDate;

  Semester({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
    };
  }

  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'] as int?,
      name: map['name'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
    );
  }
}

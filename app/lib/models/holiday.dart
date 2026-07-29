class Holiday {
  final int? id;
  final int semId;
  final String date;
  final String name;

  Holiday({
    this.id,
    required this.semId,
    required this.date,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sem_id': semId,
      'date': date,
      'name': name,
    };
  }

  factory Holiday.fromMap(Map<String, dynamic> map) {
    return Holiday(
      id: map['id'] as int?,
      semId: map['sem_id'] as int,
      date: map['date'] as String,
      name: map['name'] as String,
    );
  }
}

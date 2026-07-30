import '../config/database.dart';
import '../models/subject.dart';

class SubjectRepo {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertSubject(Subject subject) async {
    final db = await dbHelper.database;
    return await db.insert('Subjects', subject.toMap());
  }

  Future<List<Subject>> getSubjectsForSemester(int semId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Subjects',
      where: 'sem_id = ?',
      whereArgs: [semId],
    );
    return List.generate(maps.length, (i) => Subject.fromMap(maps[i]));
  }

  Future<int> deleteSubject(int id) async {
    final db = await dbHelper.database;
    return await db.delete('Subjects', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await dbHelper.database;
    return await db.update('Subjects', subject.toMap(), where: 'id = ?', whereArgs: [subject.id]);
  }
}

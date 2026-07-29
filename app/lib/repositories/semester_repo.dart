import '../config/database.dart';
import '../models/semester.dart';

class SemesterRepo {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertSemester(Semester semester) async {
    final db = await dbHelper.database;
    return await db.insert('Semester', semester.toMap());
  }

  Future<List<Semester>> getAllSemesters() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Semester');
    return List.generate(maps.length, (i) => Semester.fromMap(maps[i]));
  }

  Future<Semester?> getSemesterById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query('Semester', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Semester.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteSemester(int id) async {
    final db = await dbHelper.database;
    return await db.delete('Semester', where: 'id = ?', whereArgs: [id]);
  }
}

import '../config/database.dart';
import '../models/attendance.dart';

class AttendanceRepo {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertAttendance(Attendance attendance) async {
    final db = await dbHelper.database;
    return await db.insert('Attendance', attendance.toMap());
  }

  Future<List<Attendance>> getAttendanceForDate(int semId, String date) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Attendance',
      where: 'sem_id = ? AND date = ?',
      whereArgs: [semId, date],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }
  
  Future<Set<String>> getUnmarkedDates(int semId) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'Attendance',
      columns: ['date'],
      where: 'sem_id = ? AND student_status = ?',
      whereArgs: [semId, 'U'],
      distinct: true,
    );
    return rows.map((r) => r['date'] as String).toSet();
  }

  Future<int> updateAttendanceStatus(int id, String studentStatus, int isCancelled) async {
    final db = await dbHelper.database;
    return await db.update(
      'Attendance',
      {'student_status': studentStatus, 'is_cancelled': isCancelled},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

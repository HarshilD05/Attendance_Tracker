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
  
  Future<int> updateAttendanceStatus(int id, String studentStatus, String lecStatus) async {
    final db = await dbHelper.database;
    return await db.update(
      'Attendance',
      {'student_status': studentStatus, 'lec_status': lecStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

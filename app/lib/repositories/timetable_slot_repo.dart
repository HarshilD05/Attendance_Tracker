import '../config/database.dart';
import '../models/timetable.dart';

class TimetableSlotRepo {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTimetable(TimetableSlot timetable) async {
    final db = await dbHelper.database;
    return await db.insert('TimetableSlot', timetable.toMap());
  }

  Future<List<TimetableSlot>> getTimetableForDay(int semId, int dayOfWeek) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'TimetableSlot',
      where: 'sem_id = ? AND day_of_week = ?',
      whereArgs: [semId, dayOfWeek],
      orderBy: 'start_time ASC',
    );
    return List.generate(maps.length, (i) => TimetableSlot.fromMap(maps[i]));
  }

  Future<int> deleteTimetable(int slotId) async {
    final db = await dbHelper.database;
    return await db.delete('TimetableSlot', where: 'slot_id = ?', whereArgs: [slotId]);
  }
}

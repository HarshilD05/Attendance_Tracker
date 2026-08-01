import '../config/database.dart';
import '../models/holiday.dart';

class HolidayRepo {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertHoliday(Holiday holiday) async {
    final db = await dbHelper.database;
    return await db.insert('Holiday', holiday.toMap());
  }

  Future<List<Holiday>> getHolidaysForSemester(int semId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Holiday',
      where: 'sem_id = ?',
      whereArgs: [semId],
    );
    return List.generate(maps.length, (i) => Holiday.fromMap(maps[i]));
  }

  Future<int> deleteHoliday(int holidayId) async {
    final db = await dbHelper.database;
    return await db.delete('Holiday', where: 'id = ?', whereArgs: [holidayId]);
  }
}

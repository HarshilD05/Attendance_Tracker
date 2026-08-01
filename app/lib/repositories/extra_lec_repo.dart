import '../config/database.dart';
import '../models/extra_lec.dart';

class ExtraLecRepo {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertExtraLec(ExtraLec slot) async {
    final db = await dbHelper.database;
    return await db.insert('ExtraLec', slot.toMap());
  }

  Future<List<ExtraLec>> getExtraLecsForDate(int semId, String date) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'ExtraLec',
      where: 'sem_id = ? AND date = ?',
      whereArgs: [semId, date],
      orderBy: 'start_time ASC',
    );
    return maps.map((m) => ExtraLec.fromMap(m)).toList();
  }

  Future<int> deleteExtraLec(int id) async {
    final db = await dbHelper.database;
    return await db.delete('ExtraLec', where: 'id = ?', whereArgs: [id]);
  }
}

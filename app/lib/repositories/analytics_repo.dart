import '../config/database.dart';
import '../models/analytics_data.dart';

class AnalyticsRepo {
  final dbHelper = DatabaseHelper.instance;

  /// Get attendance stats for a single subject within optional date range.
  /// Only counts rows where is_cancelled = 0.
  Future<AttendanceStats> getSubjectStats(
    int semId,
    int subId, {
    String? startDate,
    String? endDate,
  }) async {
    final db = await dbHelper.database;

    String where = 'sem_id = ? AND sub_id = ? AND is_cancelled = ?';
    List<dynamic> args = [semId, subId, 0];

    if (startDate != null) {
      where += ' AND date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      args.add(endDate);
    }

    final rows = await db.query('Attendance', where: where, whereArgs: args);

    int attended = 0;
    int unmarked = 0;
    int total = rows.length;
    for (final row in rows) {
      if (row['student_status'] == 'P') attended++;
      else if (row['student_status'] == 'U') unmarked++;
    }

    return AttendanceStats(
      attended: attended,
      total: total,
      absent: total - attended - unmarked,
      unmarked: unmarked,
    );
  }

  /// Get stats for all subjects in a semester, keyed by subId.
  Future<Map<int, AttendanceStats>> getAllSubjectStats(
    int semId, {
    String? startDate,
    String? endDate,
  }) async {
    final db = await dbHelper.database;

    String where = 'sem_id = ? AND is_cancelled = ?';
    List<dynamic> args = [semId, 0];

    if (startDate != null) {
      where += ' AND date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      args.add(endDate);
    }

    final rows = await db.query('Attendance', where: where, whereArgs: args);

    final Map<int, int> attended = {};
    final Map<int, int> unmarked = {};
    final Map<int, int> total = {};

    for (final row in rows) {
      final subId = row['sub_id'] as int;
      total[subId] = (total[subId] ?? 0) + 1;
      if (row['student_status'] == 'P') {
        attended[subId] = (attended[subId] ?? 0) + 1;
      } else if (row['student_status'] == 'U') {
        unmarked[subId] = (unmarked[subId] ?? 0) + 1;
      }
    }

    final Map<int, AttendanceStats> result = {};
    for (final subId in total.keys) {
      final t = total[subId]!;
      final a = attended[subId] ?? 0;
      final u = unmarked[subId] ?? 0;
      result[subId] = AttendanceStats(attended: a, total: t, absent: t - a - u, unmarked: u);
    }
    return result;
  }

  /// Get monthly attendance breakdown for a semester, optionally filtered by subject.
  /// Returns a map keyed by "YYYY-MM" month strings.
  Future<Map<String, AttendanceStats>> getStatsByMonth(
    int semId, {
    int? subId,
  }) async {
    final db = await dbHelper.database;

    String where = 'sem_id = ? AND is_cancelled = ?';
    List<dynamic> args = [semId, 0];
    if (subId != null) {
      where += ' AND sub_id = ?';
      args.add(subId);
    }

    final rows = await db.query('Attendance', where: where, whereArgs: args);

    final Map<String, int> attendedByMonth = {};
    final Map<String, int> unmarkedByMonth = {};
    final Map<String, int> totalByMonth = {};

    for (final row in rows) {
      final date = row['date'] as String; // "yyyy-MM-dd"
      final monthKey = date.substring(0, 7);  // "yyyy-MM"
      totalByMonth[monthKey] = (totalByMonth[monthKey] ?? 0) + 1;
      if (row['student_status'] == 'P') {
        attendedByMonth[monthKey] = (attendedByMonth[monthKey] ?? 0) + 1;
      } else if (row['student_status'] == 'U') {
        unmarkedByMonth[monthKey] = (unmarkedByMonth[monthKey] ?? 0) + 1;
      }
    }

    final Map<String, AttendanceStats> result = {};
    for (final key in totalByMonth.keys) {
      final t = totalByMonth[key]!;
      final a = attendedByMonth[key] ?? 0;
      final u = unmarkedByMonth[key] ?? 0;
      result[key] = AttendanceStats(attended: a, total: t, absent: t - a - u, unmarked: u);
    }
    return result;
  }

  /// Get per-subject stats for a specific month (YYYY-MM).
  Future<Map<int, AttendanceStats>> getSubjectStatsByMonth(
    int semId,
    String monthKey, // "YYYY-MM"
  ) async {
    final db = await dbHelper.database;

    // SQLite: use LIKE for month prefix match on date column
    final rows = await db.query(
      'Attendance',
      where: 'sem_id = ? AND is_cancelled = ? AND date LIKE ?',
      whereArgs: [semId, 0, '$monthKey%'],
    );

    final Map<int, int> attended = {};
    final Map<int, int> unmarked = {};
    final Map<int, int> total = {};

    for (final row in rows) {
      final subId = row['sub_id'] as int;
      total[subId] = (total[subId] ?? 0) + 1;
      if (row['student_status'] == 'P') {
        attended[subId] = (attended[subId] ?? 0) + 1;
      } else if (row['student_status'] == 'U') {
        unmarked[subId] = (unmarked[subId] ?? 0) + 1;
      }
    }

    final Map<int, AttendanceStats> result = {};
    for (final subId in total.keys) {
      final t = total[subId]!;
      final a = attended[subId] ?? 0;
      final u = unmarked[subId] ?? 0;
      result[subId] = AttendanceStats(attended: a, total: t, absent: t - a - u, unmarked: u);
    }
    return result;
  }
}

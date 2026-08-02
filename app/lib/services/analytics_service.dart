import 'package:intl/intl.dart';
import '../models/analytics_data.dart';
import '../models/timetable_slot.dart';
import '../models/holiday.dart';

/// Pure computation layer — no DB calls.
/// All methods are static and side-effect free.
class AnalyticsService {
  /// Calculate how many lectures a student can still miss while staying at/above minReq.
  /// Capped at 0 (never negative).
  static int computeMissable(int attended, int total, int remaining, double minReq) {
    if (total + remaining == 0) return 0;
    final req = minReq / 100;
    // (attended) / (total + remaining - x) >= req
    // => x <= (attended - req * (total + remaining)) / (1 - req)  [if req < 1]
    if (req >= 1.0) return 0;
    final missable = ((attended - req * (total + remaining)) / (1 - req)).floor();
    return missable < 0 ? 0 : missable;
  }

  /// Calculate how many consecutive lectures must be attended to reach minReq.
  /// Returns 0 if already at or above threshold.
  static int computeToRecover(int attended, int total, int remaining, double minReq) {
    final req = minReq / 100;
    final currentPct = total == 0 ? 0.0 : attended / total;
    if (currentPct >= req) return 0;

    // Need x more present: (attended + x) / (total + x) >= req
    // => x >= (req * total - attended) / (1 - req)
    if (req >= 1.0) return remaining; // Edge case
    final needed = ((req * total - attended) / (1 - req)).ceil();
    return needed < 0 ? 0 : needed;
  }

  /// Walk the calendar from today to semester end date, counting scheduled lectures
  /// that fall on non-holiday days, across all timetable slots.
  ///
  /// [slots] — all slots for the semester (all days).
  /// [holidays] — all holidays for the semester.
  /// [endDate] — semester end date.
  /// [subId] — if provided, only counts slots for this subject.
  static int computeRemainingLecs({
    required List<TimetableSlot> slots,
    required List<Holiday> holidays,
    required DateTime endDate,
    required DateTime referenceDate,
    int? subId,
  }) {
    final holidaySet = holidays.map((h) => h.date).toSet();

    // Group slots by day of week for fast lookup
    final Map<int, List<TimetableSlot>> slotsByDay = {};
    for (final slot in slots) {
      if (subId != null && slot.subId != subId) continue;
      slotsByDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    int count = 0;
    // Start from tomorrow (today's lectures may already be partially marked)
    DateTime current = referenceDate.add(const Duration(days: 1));
    // Normalize to date only
    current = DateTime(current.year, current.month, current.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(end)) {
      final dateStr = DateFormat('yyyy-MM-dd').format(current);
      final dayOfWeek = current.weekday; // 1=Mon, 7=Sun

      if (!holidaySet.contains(dateStr) && slotsByDay.containsKey(dayOfWeek)) {
        count += slotsByDay[dayOfWeek]!.length;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  /// Derive the list of "Mon YYYY" month labels that fall within a semester range.
  static List<({String key, String label})> getMonthsInSemester(
    String startDateStr,
    String endDateStr,
  ) {
    final format = DateFormat('yyyy-MM-dd');
    final labelFormat = DateFormat('MMM yyyy');
    final start = format.parse(startDateStr);
    final end = format.parse(endDateStr);

    final List<({String key, String label})> months = [];
    final now = DateTime.now();

    // Start from first day of semester's month
    DateTime current = DateTime(start.year, start.month, 1);

    while (!current.isAfter(end)) {
      // Only include months that have started (up to current month)
      if (!current.isAfter(DateTime(now.year, now.month, 1))) {
        final key = DateFormat('yyyy-MM').format(current);
        final label = labelFormat.format(current);
        months.add((key: key, label: label));
      }
      // Advance to next month
      current = DateTime(current.year, current.month + 1, 1);
    }

    return months;
  }

  /// Build overall AttendanceStats by summing all subject stats.
  static AttendanceStats aggregateOverall(Iterable<AttendanceStats> subjectStats) {
    int totalAttended = 0;
    int totalConducted = 0;
    int totalAbsent = 0;
    int totalUnmarked = 0;
    for (final s in subjectStats) {
      totalAttended += s.attended;
      totalConducted += s.total;
      totalAbsent += s.absent;
      totalUnmarked += s.unmarked;
    }
    return AttendanceStats(
      attended: totalAttended,
      total: totalConducted,
      absent: totalAbsent,
      unmarked: totalUnmarked,
    );
  }

  /// Build a full AttendanceCardData for a given scope.
  static AttendanceCardData buildCardData({
    required String label,
    required AttendanceStats stats,
    required double minReq,
    required int remaining,
    bool hideRemaining = false,
  }) {
    final missable = computeMissable(stats.attended, stats.total, remaining, minReq);
    final toRecover = computeToRecover(stats.attended, stats.total, remaining, minReq);
    return AttendanceCardData(
      label: label,
      stats: stats,
      minReq: minReq,
      missable: missable,
      toRecover: toRecover,
      remainingLecs: hideRemaining ? null : remaining,
    );
  }

  /// Build monthly bar chart data from a map of monthKey → AttendanceStats.
  static List<MonthlyBarData> buildBarData(Map<String, AttendanceStats> statsByMonth) {
    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);
    final labelFormat = DateFormat('MMM yyyy');

    final sorted = statsByMonth.keys.toList()..sort();
    return sorted.map((key) {
      final parts = key.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return MonthlyBarData(
        monthKey: key,
        monthLabel: labelFormat.format(dt),
        percentage: statsByMonth[key]!.percentage,
        unmarkedPercentage: statsByMonth[key]!.unmarkedPercentage,
        isCurrent: key == currentMonthKey,
      );
    }).toList();
  }
}

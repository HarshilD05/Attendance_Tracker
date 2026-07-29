/// Pure data class representing attendance counts for a scope (subject/overall/monthly)
class AttendanceStats {
  final int attended;
  final int total;    // Only conducted lectures
  final int absent;

  const AttendanceStats({
    required this.attended,
    required this.total,
    required this.absent,
  });

  double get percentage => total == 0 ? 0.0 : (attended / total) * 100;

  static const AttendanceStats empty = AttendanceStats(attended: 0, total: 0, absent: 0);
}

/// Full data model for the reusable AttendanceCard widget
class AttendanceCardData {
  final String label;
  final AttendanceStats stats;
  final double minReq;         // For donut color coding
  final int missable;          // Lecs you can still skip (≥0, 0 if already below)
  final int toRecover;         // Consecutive lecs needed to recover (0 if already safe)
  final int? remainingLecs;    // null = hide in Monthly view

  const AttendanceCardData({
    required this.label,
    required this.stats,
    required this.minReq,
    required this.missable,
    required this.toRecover,
    this.remainingLecs,
  });
}

/// Per-subject analytics data
class SubjectAnalyticsData {
  final int subId;
  final String subjectName;
  final AttendanceStats stats;
  final double minReq;
  final int missable;
  final int toRecover;
  final int? remainingLecs;

  const SubjectAnalyticsData({
    required this.subId,
    required this.subjectName,
    required this.stats,
    required this.minReq,
    required this.missable,
    required this.toRecover,
    this.remainingLecs,
  });

  AttendanceCardData toCardData() => AttendanceCardData(
    label: subjectName,
    stats: stats,
    minReq: minReq,
    missable: missable,
    toRecover: toRecover,
    remainingLecs: remainingLecs,
  );
}

/// Monthly bar chart data point
class MonthlyBarData {
  final String monthLabel;   // e.g. "Jul 2025"
  final String monthKey;     // e.g. "2025-07" for sorting/filtering
  final double percentage;
  final bool isCurrent;

  const MonthlyBarData({
    required this.monthLabel,
    required this.monthKey,
    required this.percentage,
    required this.isCurrent,
  });
}

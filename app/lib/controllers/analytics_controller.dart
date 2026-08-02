import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/analytics_data.dart';
import '../models/semester.dart';
import '../models/subject.dart';
import '../models/timetable_slot.dart';
import '../repositories/analytics_repo.dart';
import '../repositories/timetable_slot_repo.dart';
import '../repositories/holiday_repo.dart';
import '../services/analytics_service.dart';

class AnalyticsController with ChangeNotifier {
  final AnalyticsRepo _analyticsRepo = AnalyticsRepo();
  final TimetableSlotRepo _timetableRepo = TimetableSlotRepo();
  final HolidayRepo _holidayRepo = HolidayRepo();

  bool _isLoading = false;
  String? _error;

  // --- Overall Tab ---
  AttendanceCardData? _overallCard;
  List<SubjectAnalyticsData> _subjectCards = [];
  List<MonthlyBarData> _overallBarData = [];

  // --- Subject Tab ---
  AttendanceCardData? _selectedSubjectCard;
  List<MonthlyBarData> _subjectBarData = [];

  // --- Monthly Tab ---
  List<({String key, String label})> _availableMonths = [];
  String? _selectedMonthKey;
  AttendanceCardData? _monthlyCard;
  List<SubjectAnalyticsData> _monthlySubjectData = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  AttendanceCardData? get overallCard => _overallCard;
  List<SubjectAnalyticsData> get subjectCards => _subjectCards;
  List<MonthlyBarData> get overallBarData => _overallBarData;
  AttendanceCardData? get selectedSubjectCard => _selectedSubjectCard;
  List<MonthlyBarData> get subjectBarData => _subjectBarData;
  List<({String key, String label})> get availableMonths => _availableMonths;
  String? get selectedMonthKey => _selectedMonthKey;
  AttendanceCardData? get monthlyCard => _monthlyCard;
  List<SubjectAnalyticsData> get monthlySubjectData => _monthlySubjectData;

  // ─── Load Overall Analytics ───────────────────────────────────────────────

  Future<void> loadOverallAnalytics(Semester semester, List<Subject> subjects) async {
    if (semester.id == null || subjects.isEmpty) return;
    _setLoading(true);

    try {
      final allSlots = await _getAllSlots(semester.id!);
      final holidays = await _holidayRepo.getHolidaysForSemester(semester.id!);
      final excludeDates = holidays.map((h) => h.date).toList();
      final endDate = DateFormat('yyyy-MM-dd').parse(semester.endDate);
      final now = DateTime.now();

      final allSubjectStats = await _analyticsRepo.getAllSubjectStats(semester.id!, excludeDates: excludeDates);

      // Build per-subject data
      final List<SubjectAnalyticsData> subjectData = [];
      int totalRemaining = 0;

      for (final sub in subjects) {
        final stats = allSubjectStats[sub.id!] ?? AttendanceStats.empty;
        final remaining = AnalyticsService.computeRemainingLecs(
          slots: allSlots,
          holidays: holidays,
          endDate: endDate,
          referenceDate: now,
          subId: sub.id,
        );
        totalRemaining += remaining;

        subjectData.add(SubjectAnalyticsData(
          subId: sub.id!,
          subjectName: sub.name,
          stats: stats,
          minReq: sub.minAttendanceReq,
          missable: AnalyticsService.computeMissable(stats.attended, stats.total, remaining, sub.minAttendanceReq),
          toRecover: AnalyticsService.computeToRecover(stats.attended, stats.total, remaining, sub.minAttendanceReq),
          remainingLecs: remaining,
        ));
      }

      _subjectCards = subjectData;

      // Build overall card (sum of all subjects)
      final overallStats = AnalyticsService.aggregateOverall(allSubjectStats.values);
      _overallCard = AnalyticsService.buildCardData(
        label: 'Overall Semester',
        stats: overallStats,
        minReq: semester.minAttendanceReq,
        remaining: totalRemaining,
      );

      // Build overall monthly bar data
      final overallStatsByMonth = await _analyticsRepo.getStatsByMonth(semester.id!, excludeDates: excludeDates);
      _overallBarData = AnalyticsService.buildBarData(overallStatsByMonth);

      // Also set up available months for monthly tab
      _availableMonths = AnalyticsService.getMonthsInSemester(semester.startDate, semester.endDate);
      if (_availableMonths.isNotEmpty) {
        if (_selectedMonthKey == null || !_availableMonths.any((m) => m.key == _selectedMonthKey)) {
          _selectedMonthKey = _availableMonths.last.key;
        }
      } else {
        _selectedMonthKey = null;
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load analytics: $e';
    }

    _setLoading(false);
  }

  // ─── Load Subject Analytics ───────────────────────────────────────────────

  Future<void> loadSubjectAnalytics(Semester semester, Subject subject) async {
    if (semester.id == null) return;
    _setLoading(true);

    try {
      final allSlots = await _getAllSlots(semester.id!);
      final holidays = await _holidayRepo.getHolidaysForSemester(semester.id!);
      final excludeDates = holidays.map((h) => h.date).toList();
      final endDate = DateFormat('yyyy-MM-dd').parse(semester.endDate);
      final now = DateTime.now();

      final stats = await _analyticsRepo.getSubjectStats(semester.id!, subject.id!, excludeDates: excludeDates);
      final remaining = AnalyticsService.computeRemainingLecs(
        slots: allSlots,
        holidays: holidays,
        endDate: endDate,
        referenceDate: now,
        subId: subject.id,
      );

      _selectedSubjectCard = AnalyticsService.buildCardData(
        label: subject.name,
        stats: stats,
        minReq: subject.minAttendanceReq,
        remaining: remaining,
      );

      // Build monthly bar data for this subject
      final statsByMonth = await _analyticsRepo.getStatsByMonth(semester.id!, subId: subject.id, excludeDates: excludeDates);
      _subjectBarData = AnalyticsService.buildBarData(statsByMonth);

      _error = null;
    } catch (e) {
      _error = 'Failed to load subject analytics: $e';
    }

    _setLoading(false);
  }

  // ─── Load Monthly Analytics ───────────────────────────────────────────────

  Future<void> loadMonthlyAnalytics(Semester semester, List<Subject> subjects, String monthKey) async {
    if (semester.id == null) return;
    _selectedMonthKey = monthKey;
    _setLoading(true);

    try {
      final holidays = await _holidayRepo.getHolidaysForSemester(semester.id!);
      final excludeDates = holidays.map((h) => h.date).toList();
      final subjectStatsByMonth = await _analyticsRepo.getSubjectStatsByMonth(semester.id!, monthKey, excludeDates: excludeDates);

      // Overall for the month
      final overallStats = AnalyticsService.aggregateOverall(subjectStatsByMonth.values);
      _monthlyCard = AttendanceCardData(
        label: _monthLabel(monthKey),
        stats: overallStats,
        minReq: semester.minAttendanceReq,
        missable: null,
        toRecover: null,
        remainingLecs: null, // Hidden in monthly view
      );

      // Per-subject for the month
      _monthlySubjectData = subjects.map((sub) {
        final stats = subjectStatsByMonth[sub.id!] ?? AttendanceStats.empty;
        return SubjectAnalyticsData(
          subId: sub.id!,
          subjectName: sub.name,
          stats: stats,
          minReq: sub.minAttendanceReq,
          missable: 0,
          toRecover: 0,
          remainingLecs: null,
        );
      }).toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load monthly analytics: $e';
    }

    _setLoading(false);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<List<TimetableSlot>> _getAllSlots(int semId) async {
    // Fetch slots for all 7 days and combine
    final List<TimetableSlot> all = [];
    for (int day = 1; day <= 7; day++) {
      final slots = await _timetableRepo.getTimetableForDay(semId, day);
      all.addAll(slots);
    }
    return all;
  }

  String _monthLabel(String monthKey) {
    final parts = monthKey.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMM yyyy').format(dt);
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../models/timetable_slot.dart';
import '../models/semester.dart';
import '../repositories/timetable_slot_repo.dart';
import '../repositories/attendance_repo.dart';
import '../repositories/holiday_repo.dart';

class AttendanceController with ChangeNotifier {
  final TimetableSlotRepo _timetableRepo = TimetableSlotRepo();
  final AttendanceRepo _attendanceRepo = AttendanceRepo();

  DateTime _selectedDate = DateTime.now();
  List<TimetableSlot> _todaysSchedule = [];
  List<Attendance> _todaysAttendance = [];
  Set<String> _unmarkedDates = {};

  DateTime get selectedDate => _selectedDate;
  List<TimetableSlot> get todaysSchedule => _todaysSchedule;
  List<Attendance> get todaysAttendance => _todaysAttendance;
  Set<String> get unmarkedDates => _unmarkedDates;

  Future<void> loadUnmarkedDates(int semId) async {
    _unmarkedDates = await _attendanceRepo.getUnmarkedDates(semId);
    notifyListeners();
  }

  void setSelectedDate(DateTime date, int semId) {
    _selectedDate = date;
    loadScheduleForDate(semId);
  }

  Future<String?> loadScheduleForDate(int semId) async {
    try {
      final dayOfWeek = _selectedDate.weekday; // 1 = Monday, 7 = Sunday
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      _todaysSchedule = await _timetableRepo.getTimetableForDay(semId, dayOfWeek);
      _todaysAttendance = await _attendanceRepo.getAttendanceForDate(semId, dateStr);
      
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to load schedule.';
    }
  }

  Future<String?> markAttendance(int semId, int subId, int? slotId, int isCancelled, String studentStatus) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Check if attendance already exists for this slot and date
      final existingIndex = _todaysAttendance.indexWhere((a) => a.slotId == slotId && a.subId == subId);
      
      if (existingIndex >= 0) {
        final existing = _todaysAttendance[existingIndex];
        await _attendanceRepo.updateAttendanceStatus(existing.id!, studentStatus, isCancelled);
      } else {
        final attendance = Attendance(
          semId: semId,
          subId: subId,
          slotId: slotId,
          date: dateStr,
          isCancelled: isCancelled,
          studentStatus: studentStatus,
        );
        await _attendanceRepo.insertAttendance(attendance);
      }
      
      // Reload
      await loadScheduleForDate(semId);
      await loadUnmarkedDates(semId);
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to mark attendance.';
    }
  }

  Future<void> backfillUnmarked(Semester sem) async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final todayDate = DateFormat('yyyy-MM-dd').parse(todayStr);
      final semStart = DateFormat('yyyy-MM-dd').parse(sem.startDate);
      if (todayDate.isBefore(semStart)) return;

      final holidays = await HolidayRepo().getHolidaysForSemester(sem.id!);
      final holidaySet = holidays.map((h) => h.date).toSet();

      final allSlots = <TimetableSlot>[];
      for (int d = 1; d <= 7; d++) {
        allSlots.addAll(await _timetableRepo.getTimetableForDay(sem.id!, d));
      }
      final Map<int, List<TimetableSlot>> slotsByDay = {};
      for (final slot in allSlots) {
        slotsByDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
      }

      var current = semStart;
      while (!current.isAfter(todayDate)) {
        final dateStr = DateFormat('yyyy-MM-dd').format(current);
        final dayOfWeek = current.weekday;

        if (!holidaySet.contains(dateStr) && slotsByDay.containsKey(dayOfWeek)) {
          final existingAtt = await _attendanceRepo.getAttendanceForDate(sem.id!, dateStr);
          final existingSlotIds = existingAtt.map((a) => a.slotId).toSet();

          for (final slot in slotsByDay[dayOfWeek]!) {
            if (!existingSlotIds.contains(slot.slotId)) {
              await _attendanceRepo.insertAttendance(Attendance(
                semId: sem.id!,
                subId: slot.subId,
                slotId: slot.slotId,
                date: dateStr,
                isCancelled: 0,
                studentStatus: 'U',
              ));
            }
          }
        }
        current = current.add(const Duration(days: 1));
      }
    } catch (e) {
      debugPrint("Backfill Error: $e");
    }
  }

  /// Mark all slots for the selected day at once.
  Future<String?> markAllAttendance(
    int semId,
    List<TimetableSlot> slots,
    String studentStatus,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      for (final slot in slots) {
        final existingIndex = _todaysAttendance.indexWhere(
          (a) => a.slotId == slot.slotId && a.subId == slot.subId,
        );
        if (existingIndex >= 0) {
          final existing = _todaysAttendance[existingIndex];
          await _attendanceRepo.updateAttendanceStatus(existing.id!, studentStatus, 0);
        } else {
          await _attendanceRepo.insertAttendance(Attendance(
            semId: semId,
            subId: slot.subId,
            slotId: slot.slotId,
            date: dateStr,
            isCancelled: 0,
            studentStatus: studentStatus,
          ));
        }
      }
      await loadScheduleForDate(semId);
      await loadUnmarkedDates(semId);
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to mark all attendance.';
    }
  }
}

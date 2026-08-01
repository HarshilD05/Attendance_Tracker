import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../models/timetable_slot.dart';
import '../models/semester.dart';
import '../repositories/timetable_slot_repo.dart';
import '../repositories/attendance_repo.dart';
import '../repositories/holiday_repo.dart';
import '../models/holiday.dart';
import '../repositories/extra_lec_repo.dart';
import '../models/extra_lec.dart';

class AttendanceController with ChangeNotifier {
  final TimetableSlotRepo _timetableRepo = TimetableSlotRepo();
  final AttendanceRepo _attendanceRepo = AttendanceRepo();
  final ExtraLecRepo _extraLecRepo = ExtraLecRepo();

  DateTime _selectedDate = DateTime.now();
  List<TimetableSlot> _todaysSchedule = [];
  List<Attendance> _todaysAttendance = [];
  Set<String> _unmarkedDates = {};
  bool _isHoliday = false;
  Holiday? _currentHoliday;

  DateTime get selectedDate => _selectedDate;
  List<TimetableSlot> get todaysSchedule => _todaysSchedule;
  List<Attendance> get todaysAttendance => _todaysAttendance;
  Set<String> get unmarkedDates => _unmarkedDates;
  bool get isHoliday => _isHoliday;
  Holiday? get currentHoliday => _currentHoliday;

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

      // Check for holiday
      final holidays = await HolidayRepo().getHolidaysForSemester(semId);
      final index = holidays.indexWhere((h) => h.date == dateStr);
      if (index >= 0) {
        _isHoliday = true;
        _currentHoliday = holidays[index];
      } else {
        _isHoliday = false;
        _currentHoliday = null;
      }

      final regular = await _timetableRepo.getTimetableForDay(semId, dayOfWeek);
      final extraLecRaw = await _extraLecRepo.getExtraLecsForDate(semId, dateStr);
      
      final extraLec = extraLecRaw.map((a) => TimetableSlot(
        extraLecId: a.id,
        semId: a.semId,
        subId: a.subId,
        dayOfWeek: 0,
        startTime: a.startTime,
        endTime: a.endTime,
        classRoom: a.classRoom,
        specificDate: a.date,
      )).toList();

      _todaysSchedule = [...regular, ...extraLec]
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      _todaysAttendance = await _attendanceRepo.getAttendanceForDate(semId, dateStr);
      
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to load schedule.';
    }
  }

  /// Add a one-time ad-hoc lecture for the selected date.
  /// Returns an error string if there's a time overlap, otherwise null.
  Future<String?> addExtraLec(int semId, TimetableSlot slot) async {
    try {
      // Check for overlaps against existing slots for this day
      for (final existing in _todaysSchedule) {
        final isExtra = existing.isExtraLec;
        final targetId = isExtra ? existing.extraLecId : existing.slotId;
        final existingIndex = _todaysAttendance.indexWhere(
          (a) => (a.slotId != null && a.slotId == targetId && !isExtra) || 
                 (a.extraLecId != null && a.extraLecId == targetId && isExtra)
        );
        if (existingIndex >= 0 && _todaysAttendance[existingIndex].isCancelled == 1) {
          continue; // Ignore cancelled slots for overlap check
        }

        final newStart = slot.startTime.replaceAll(':', '').padLeft(4, '0');
        final newEnd   = slot.endTime.replaceAll(':', '').padLeft(4, '0');
        final exStart  = existing.startTime.replaceAll(':', '').padLeft(4, '0');
        final exEnd    = existing.endTime.replaceAll(':', '').padLeft(4, '0');
        // Overlap if new start < existing end AND new end > existing start
        if (newStart.compareTo(exEnd) < 0 && newEnd.compareTo(exStart) > 0) {
          return 'Time overlaps with an existing slot (${existing.startTime} – ${existing.endTime})';
        }
      }
      
      final extraLecSlot = ExtraLec(
        semId: semId,
        subId: slot.subId,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime: slot.startTime,
        endTime: slot.endTime,
        classRoom: slot.classRoom,
      );

      final newExtraLecId = await _extraLecRepo.insertExtraLec(extraLecSlot);
      // Insert an Unmarked attendance record immediately
      final insertDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await _attendanceRepo.insertAttendance(Attendance(
        semId: semId,
        subId: slot.subId,
        extraLecId: newExtraLecId,
        date: insertDateStr,
        isCancelled: 0,
        studentStatus: 'U',
      ));
      await loadScheduleForDate(semId);
      await loadUnmarkedDates(semId);
      return null;
    } catch (e) {
      debugPrint("ExtraLec Error: $e");
      return 'Failed to add extra lecture.';
    }
  }

  Future<String?> removeExtraLec(int semId, int extraLecId) async {
    try {
      await _extraLecRepo.deleteExtraLec(extraLecId);
      await loadScheduleForDate(semId);
      await loadUnmarkedDates(semId);
      return null;
    } catch (e) {
      debugPrint("Remove ExtraLec Error: $e");
      return 'Failed to remove extra lecture.';
    }
  }

  Future<String?> markAttendance(int semId, TimetableSlot slot, int isCancelled, String studentStatus) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final isExtraLec = slot.isExtraLec;
      final targetId = isExtraLec ? slot.extraLecId : slot.slotId;
      
      // Check if attendance already exists for this slot and date
      final existingIndex = _todaysAttendance.indexWhere(
        (a) => (a.slotId != null && a.slotId == targetId && !isExtraLec) || 
               (a.extraLecId != null && a.extraLecId == targetId && isExtraLec)
      );
      
      if (existingIndex >= 0) {
        final existing = _todaysAttendance[existingIndex];
        await _attendanceRepo.updateAttendanceStatus(existing.id!, studentStatus, isCancelled);
      } else {
        final attendance = Attendance(
          semId: semId,
          subId: slot.subId,
          slotId: isExtraLec ? null : slot.slotId,
          extraLecId: isExtraLec ? slot.extraLecId : null,
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
        final isExtraLec = slot.isExtraLec;
        final targetId = isExtraLec ? slot.extraLecId : slot.slotId;
        
        final existingIndex = _todaysAttendance.indexWhere(
          (a) => (a.slotId != null && a.slotId == targetId && !isExtraLec) || 
                 (a.extraLecId != null && a.extraLecId == targetId && isExtraLec)
        );
        if (existingIndex >= 0) {
          final existing = _todaysAttendance[existingIndex];
          await _attendanceRepo.updateAttendanceStatus(existing.id!, studentStatus, 0);
        } else {
          await _attendanceRepo.insertAttendance(Attendance(
            semId: semId,
            subId: slot.subId,
            slotId: isExtraLec ? null : slot.slotId,
            extraLecId: isExtraLec ? slot.extraLecId : null,
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

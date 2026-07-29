import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../models/timetable.dart';
import '../repositories/timetable_repo.dart';
import '../repositories/attendance_repo.dart';

class AttendanceController with ChangeNotifier {
  final TimetableSlotRepo _timetableRepo = TimetableSlotRepo();
  final AttendanceRepo _attendanceRepo = AttendanceRepo();

  DateTime _selectedDate = DateTime.now();
  List<TimetableSlot> _todaysSchedule = [];
  List<Attendance> _todaysAttendance = [];

  DateTime get selectedDate => _selectedDate;
  List<TimetableSlot> get todaysSchedule => _todaysSchedule;
  List<Attendance> get todaysAttendance => _todaysAttendance;

  void setSelectedDate(DateTime date, int semId) {
    _selectedDate = date;
    loadScheduleForDate(semId);
  }

  Future<void> loadScheduleForDate(int semId) async {
    final dayOfWeek = _selectedDate.weekday; // 1 = Monday, 7 = Sunday
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    _todaysSchedule = await _timetableRepo.getTimetableForDay(semId, dayOfWeek);
    _todaysAttendance = await _attendanceRepo.getAttendanceForDate(semId, dateStr);
    
    notifyListeners();
  }

  Future<void> markAttendance(int semId, int subId, int? slotId, String lecStatus, String studentStatus) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    // Check if attendance already exists for this slot and date
    final existingIndex = _todaysAttendance.indexWhere((a) => a.slotId == slotId && a.subId == subId);
    
    if (existingIndex >= 0) {
      final existing = _todaysAttendance[existingIndex];
      await _attendanceRepo.updateAttendanceStatus(existing.id!, studentStatus, lecStatus);
    } else {
      final attendance = Attendance(
        semId: semId,
        subId: subId,
        slotId: slotId,
        date: dateStr,
        lecStatus: lecStatus,
        studentStatus: studentStatus,
      );
      await _attendanceRepo.insertAttendance(attendance);
    }
    
    // Reload
    await loadScheduleForDate(semId);
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/semester.dart';
import '../models/holiday.dart';
import '../repositories/semester_repo.dart';
import '../repositories/holiday_repo.dart';
import '../repositories/subject_repo.dart';
import '../repositories/timetable_slot_repo.dart';
import '../repositories/attendance_repo.dart';
import '../repositories/extra_lec_repo.dart';
import '../models/semester_export.dart';
import '../models/subject.dart';
import '../models/timetable_slot.dart';

class SemesterController with ChangeNotifier {
  final SemesterRepo _semesterRepo = SemesterRepo();
  final HolidayRepo _holidayRepo = HolidayRepo();
  final AttendanceRepo _attendanceRepo = AttendanceRepo();
  final ExtraLecRepo _extraLecRepo = ExtraLecRepo();

  List<Semester> _semesters = [];
  Semester? _activeSemester;
  bool _isLoading = true;

  List<Semester> get semesters => _semesters;
  Semester? get activeSemester => _activeSemester;
  bool get isLoading => _isLoading;

  Future<String?> loadSemesters() async {
    _isLoading = true;
    notifyListeners();
    try {
      _semesters = await _semesterRepo.getAllSemesters();
      if (_semesters.isNotEmpty && _activeSemester == null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final format = DateFormat('yyyy-MM-dd');
        
        Semester? matchedSemester;
        for (var sem in _semesters) {
          try {
            final start = format.parse(sem.startDate);
            final end = format.parse(sem.endDate);
            if ((today.isAfter(start) || today.isAtSameMomentAs(start)) && 
                (today.isBefore(end) || today.isAtSameMomentAs(end))) {
              matchedSemester = sem;
              break;
            }
          } catch (e) {
            // ignore parsing errors and continue
          }
        }
        _activeSemester = matchedSemester;
      }
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      _isLoading = false;
      notifyListeners();
      return 'Failed to load semesters.';
    }
  }

  void setActiveSemester(Semester semester) {
    _activeSemester = semester;
    notifyListeners();
  }

  Future<String?> createSemester(Semester semester) async {
    if (_isOverlapping(semester.startDate, semester.endDate)) {
      return 'Dates overlap with an existing semester.';
    }
    try {
      // 1. Insert Semester
      final semId = await _semesterRepo.insertSemester(semester);
      
      // 2. Automatically add all Sundays in range as holidays
      await _addSundaysAsHolidays(semId, semester.startDate, semester.endDate);
      
      await loadSemesters();
      
      // Set the newly created semester as active
      final newSem = _semesters.firstWhere((s) => s.id == semId);
      setActiveSemester(newSem);
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to create semester.';
    }
  }

  Future<String?> deleteSemester(int semId) async {
    try {
      await _semesterRepo.deleteSemester(semId);
      // Clear active semester to avoid dangling reference.
      _activeSemester = null;
      await loadSemesters();
      return null;
    } catch (e) {
      debugPrint('Delete semester error: $e');
      return 'Failed to delete semester.';
    }
  }


  Future<String?> updateSemester(Semester semester) async {
    if (_isOverlapping(semester.startDate, semester.endDate, semester.id)) {
      return 'Dates overlap with an existing semester.';
    }
    try {
      await _semesterRepo.updateSemester(semester);
      // Prune records that fall outside the new date range
      if (semester.id != null) {
        await _attendanceRepo.deleteRecordsOutsideRange(
            semester.id!, semester.startDate, semester.endDate);
        await _extraLecRepo.deleteExtraLecsOutsideRange(
            semester.id!, semester.startDate, semester.endDate);
      }
      await loadSemesters();
      if (_activeSemester?.id == semester.id) {
        _activeSemester = _semesters.firstWhere((s) => s.id == semester.id);
      }
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to update semester.';
    }
  }

  bool _isOverlapping(String newStartStr, String newEndStr, [int? ignoreId]) {
    final format = DateFormat('yyyy-MM-dd');
    try {
      final newStart = format.parse(newStartStr);
      final newEnd = format.parse(newEndStr);
      
      for (var sem in _semesters) {
        if (sem.id == ignoreId) continue;
        
        final existingStart = format.parse(sem.startDate);
        final existingEnd = format.parse(sem.endDate);
        
        if ((newStart.isBefore(existingEnd) || newStart.isAtSameMomentAs(existingEnd)) &&
            (newEnd.isAfter(existingStart) || newEnd.isAtSameMomentAs(existingStart))) {
          return true;
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }
  
  Future<void> _addSundaysAsHolidays(int semId, String startDateStr, String endDateStr) async {
    final format = DateFormat('yyyy-MM-dd');
    final startDate = format.parse(startDateStr);
    final endDate = format.parse(endDateStr);
    
    var currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      if (currentDate.weekday == DateTime.sunday) {
        final holiday = Holiday(
          semId: semId,
          date: format.format(currentDate),
          name: 'Sunday',
        );
        await _holidayRepo.insertHoliday(holiday);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  Future<String?> exportSemester(int semId) async {
    try {
      final semester = _semesters.firstWhere((s) => s.id == semId);
      final holidays = await _holidayRepo.getHolidaysForSemester(semId);
      
      final subjectRepo = SubjectRepo();
      final subjects = await subjectRepo.getSubjectsForSemester(semId);
      
      final timetableRepo = TimetableSlotRepo();
      final slots = await timetableRepo.getTimetableForSemester(semId);
      
      final Map<int, String> subjectIdToName = {
        for (var s in subjects) s.id!: s.name
      };

      // Group timetable slots by day
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final timetableMap = <String, List<Map<String, dynamic>>>{};
      
      for (var slot in slots) {
        final dayName = days[slot.dayOfWeek - 1];
        timetableMap.putIfAbsent(dayName, () => []);
        timetableMap[dayName]!.add({
          'subject_name': subjectIdToName[slot.subId] ?? 'Unknown',
          'start_time': slot.startTime,
          'end_time': slot.endTime,
          'class_room': slot.classRoom,
        });
      }

      final exportData = SemesterExportData(
        semester: semester,
        holidays: holidays,
        subjects: subjects,
        timetable: timetableMap,
      );

      return exportData.toJsonString();
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  Future<String?> importSemester(String jsonStr) async {
    try {
      final exportData = SemesterExportData.fromJsonString(jsonStr);
      
      if (_isOverlapping(exportData.semester.startDate, exportData.semester.endDate)) {
        return 'Imported dates overlap with an existing semester.';
      }

      // 1. Insert Semester
      final semId = await _semesterRepo.insertSemester(exportData.semester);
      
      // 2. Insert Holidays
      for (var h in exportData.holidays) {
        final newHoliday = Holiday(
          semId: semId,
          date: h.date,
          name: h.name,
        );
        await _holidayRepo.insertHoliday(newHoliday);
      }
      
      // 3. Insert Subjects and keep track of new IDs
      final subjectRepo = SubjectRepo();
      final Map<String, int> subjectNameToId = {};
      
      for (var s in exportData.subjects) {
        final newSubject = Subject(
          semId: semId,
          name: s.name,
          teacher: s.teacher,
          minAttendanceReq: s.minAttendanceReq,
        );
        final newSubId = await subjectRepo.insertSubject(newSubject);
        subjectNameToId[newSubject.name] = newSubId;
      }
      
      // 4. Insert Timetable Slots
      final timetableRepo = TimetableSlotRepo();
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      for (var entry in exportData.timetable.entries) {
        final dayName = entry.key;
        final dayOfWeek = days.indexOf(dayName) + 1;
        if (dayOfWeek < 1 || dayOfWeek > 7) continue;
        
        for (var rawSlot in entry.value) {
          final subName = rawSlot['subject_name'] as String;
          final subId = subjectNameToId[subName];
          if (subId == null) continue; // Skip if subject doesn't exist
          
          final newSlot = TimetableSlot(
            semId: semId,
            subId: subId,
            dayOfWeek: dayOfWeek,
            startTime: rawSlot['start_time'] as String,
            endTime: rawSlot['end_time'] as String,
            classRoom: rawSlot['class_room'] as String,
          );
          await timetableRepo.insertTimetable(newSlot);
        }
      }
      
      await loadSemesters();
      
      // Set active
      final newSem = _semesters.firstWhere((s) => s.id == semId);
      setActiveSemester(newSem);
      
      return null; // Success
    } catch (e) {
      print('Import error: $e');
      return 'Invalid Semester JSON format';
    }
  }
}

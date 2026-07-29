import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/semester.dart';
import '../models/holiday.dart';
import '../repositories/semester_repo.dart';
import '../repositories/holiday_repo.dart';

class SemesterController with ChangeNotifier {
  final SemesterRepo _semesterRepo = SemesterRepo();
  final HolidayRepo _holidayRepo = HolidayRepo();

  List<Semester> _semesters = [];
  Semester? _activeSemester;
  String? _errorMessage;

  List<Semester> get semesters => _semesters;
  Semester? get activeSemester => _activeSemester;
  String? get errorMessage => _errorMessage;

  Future<void> loadSemesters() async {
    try {
      _errorMessage = null;
      _semesters = await _semesterRepo.getAllSemesters();
      if (_semesters.isNotEmpty && _activeSemester == null) {
        _activeSemester = _semesters.last;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load semesters: $e';
      notifyListeners();
    }
  }

  void setActiveSemester(Semester semester) {
    _activeSemester = semester;
    notifyListeners();
  }

  Future<void> createSemester(Semester semester) async {
    try {
      _errorMessage = null;
      // 1. Insert Semester
      final semId = await _semesterRepo.insertSemester(semester);
      
      // 2. Automatically add all Sundays in range as holidays
      await _addSundaysAsHolidays(semId, semester.startDate, semester.endDate);
      
      await loadSemesters();
    } catch (e) {
      _errorMessage = 'Failed to create semester: $e';
      notifyListeners();
    }
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
}

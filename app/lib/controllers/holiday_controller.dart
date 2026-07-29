import 'package:flutter/material.dart';
import '../models/holiday.dart';
import '../repositories/holiday_repo.dart';

class HolidayController with ChangeNotifier {
  final HolidayRepo _holidayRepo = HolidayRepo();

  List<Holiday> _holidays = [];
  String? _errorMessage;

  List<Holiday> get holidays => _holidays;
  String? get errorMessage => _errorMessage;

  Future<void> loadHolidaysForSemester(int semId) async {
    try {
      _errorMessage = null;
      _holidays = await _holidayRepo.getHolidaysForSemester(semId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load holidays: $e';
      notifyListeners();
    }
  }

  Future<void> addHoliday(Holiday holiday) async {
    try {
      _errorMessage = null;
      await _holidayRepo.insertHoliday(holiday);
      await loadHolidaysForSemester(holiday.semId);
    } catch (e) {
      _errorMessage = 'Failed to add holiday: $e';
      notifyListeners();
    }
  }
}

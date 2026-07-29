import 'package:flutter/material.dart';
import '../models/holiday.dart';
import '../repositories/holiday_repo.dart';

class HolidayController with ChangeNotifier {
  final HolidayRepo _holidayRepo = HolidayRepo();

  List<Holiday> _holidays = [];

  List<Holiday> get holidays => _holidays;

  Future<String?> loadHolidaysForSemester(int semId) async {
    try {
      _holidays = await _holidayRepo.getHolidaysForSemester(semId);
      notifyListeners();
      return null;
    } catch (e) {
  print(e);
      return 'Failed to load holidays.';
    }
  }

  Future<String?> addHoliday(Holiday holiday) async {
    try {
      await _holidayRepo.insertHoliday(holiday);
      await loadHolidaysForSemester(holiday.semId);
      return null;
    } catch (e) {
  print(e);
      return 'Failed to add holiday.';
    }
  }

  Future<String?> removeHoliday(int holidayId, int semId) async {
    try {
      await _holidayRepo.deleteHoliday(holidayId);
      await loadHolidaysForSemester(semId);
      return null;
    } catch (e) {
  print(e);
      return 'Failed to remove holiday.';
    }
  }
}

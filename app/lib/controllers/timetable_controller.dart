import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/timetable_slot.dart';
import '../repositories/timetable_slot_repo.dart';

class TimetableController with ChangeNotifier {
  final TimetableSlotRepo _repo = TimetableSlotRepo();

  /// All timetable slots keyed by day-of-week (1=Mon … 6=Sat).
  Map<int, List<TimetableSlot>> _slotsByDay = {};
  int _selectedDayOfWeek = 1;
  bool _isLoading = false;

  Map<int, List<TimetableSlot>> get slotsByDay => _slotsByDay;
  int get selectedDayOfWeek => _selectedDayOfWeek;
  bool get isLoading => _isLoading;

  /// Kept for backwards-compat: returns slots for the currently selected day.
  List<TimetableSlot> get slots => _slotsByDay[_selectedDayOfWeek] ?? [];

  /// Preload all days at once so tab swipes are instant.
  Future<String?> loadAllTimetable(int semId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final all = await _repo.getTimetableForSemester(semId);
      final Map<int, List<TimetableSlot>> byDay = {};
      for (final slot in all) {
        byDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
      }
      _slotsByDay = byDay;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('TimetableController.loadAllTimetable error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Failed to load timetable.';
    }
  }

  void setSelectedDay(int day) {
    _selectedDayOfWeek = day;
    notifyListeners();
  }

  Future<String?> addSlot(TimetableSlot newSlot) async {
    try {
      final format = DateFormat('HH:mm');
      final newStart = format.parse(newSlot.startTime);
      final newEnd = format.parse(newSlot.endTime);

      if (newStart.isAfter(newEnd) || newStart.isAtSameMomentAs(newEnd)) {
        return 'End time must be after start time';
      }

      final daySlots = _slotsByDay[newSlot.dayOfWeek] ?? [];
      for (var slot in daySlots) {
        final existingStart = format.parse(slot.startTime);
        final existingEnd = format.parse(slot.endTime);

        bool noOverlap = newEnd.isBefore(existingStart) ||
            newEnd.isAtSameMomentAs(existingStart) ||
            newStart.isAfter(existingEnd) ||
            newStart.isAtSameMomentAs(existingEnd);

        if (!noOverlap) {
          return 'Slot overlaps with existing class (${slot.startTime} - ${slot.endTime})';
        }
      }

      await _repo.insertTimetable(newSlot);
      await loadAllTimetable(newSlot.semId);
      return null;
    } catch (e) {
      debugPrint('TimetableController.addSlot error: $e');
      return 'Failed to add slot.';
    }
  }

  Future<String?> removeSlot(int slotId, int semId) async {
    try {
      await _repo.deleteTimetable(slotId);
      await loadAllTimetable(semId);
      return null;
    } catch (e) {
      debugPrint('TimetableController.removeSlot error: $e');
      return 'Failed to remove slot.';
    }
  }
}

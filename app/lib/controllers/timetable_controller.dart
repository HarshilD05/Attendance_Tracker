import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/timetable_slot.dart';
import '../repositories/timetable_slot_repo.dart';

class TimetableController with ChangeNotifier {
  final TimetableSlotRepo _repo = TimetableSlotRepo();

  List<TimetableSlot> _slots = [];
  int _selectedDayOfWeek = 1; // 1 = Monday, 6 = Saturday

  List<TimetableSlot> get slots => _slots;
  int get selectedDayOfWeek => _selectedDayOfWeek;

  void setSelectedDay(int day, int semId) {
    _selectedDayOfWeek = day;
    loadTimetable(semId);
  }

  Future<String?> loadTimetable(int semId) async {
    try {
      _slots = await _repo.getTimetableForDay(semId, _selectedDayOfWeek);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to load timetable.';
    }
  }

  Future<String?> addSlot(TimetableSlot newSlot) async {
    try {
      // Overlap validation
      final format = DateFormat('HH:mm');
      final newStart = format.parse(newSlot.startTime);
      final newEnd = format.parse(newSlot.endTime);
      
      if (newStart.isAfter(newEnd) || newStart.isAtSameMomentAs(newEnd)) {
        return 'End time must be after start time';
      }

      for (var slot in _slots) {
        final existingStart = format.parse(slot.startTime);
        final existingEnd = format.parse(slot.endTime);
        
        bool noOverlap = newEnd.isBefore(existingStart) || newEnd.isAtSameMomentAs(existingStart) ||
                         newStart.isAfter(existingEnd) || newStart.isAtSameMomentAs(existingEnd);
                         
        if (!noOverlap) {
          return 'Slot overlaps with existing class (${slot.startTime} - ${slot.endTime})';
        }
      }

      await _repo.insertTimetable(newSlot);
      await loadTimetable(newSlot.semId);
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to add slot.';
    }
  }

  Future<String?> removeSlot(int slotId, int semId) async {
    try {
      await _repo.deleteTimetable(slotId);
      await loadTimetable(semId);
      return null;
    } catch (e) {
      debugPrint("Error : $e");
      return 'Failed to remove slot.';
    }
  }
}

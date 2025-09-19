import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable.dart';
import 'base_firestore_service.dart';

class TimetableService extends BaseFirestoreService {
  static const String _semestersCollectionName = 'semesters';

  /// Get semesters collection reference
  CollectionReference get _semestersCollection => getCollection(_semestersCollectionName);

  /// Get timetable subcollection reference (days collection)
  CollectionReference _getTimetableCollection(String semesterId) {
    return _semestersCollection.doc(semesterId).collection('timetable');
  }

  /// Add or update a time slot in a day's schedule
  Future<void> addTimeSlot(String semesterId, WeekDay day, TimeSlot timeSlot) async {
    ensureAuthenticated();
    
    try {
      // Check if semester exists
      final semesterDoc = await _semestersCollection.doc(semesterId).get();
      if (!semesterDoc.exists) {
        throw Exception('Semester not found');
      }

      final dayDoc = _getTimetableCollection(semesterId).doc(day.name);
      
      // Check if day document exists
      final daySnapshot = await dayDoc.get();
      
      if (daySnapshot.exists) {
        // Get current day schedule
        final daySchedule = DaySchedule.fromFirestore(daySnapshot);
        
        // Check for time conflicts
        if (daySchedule.hasTimeConflict(timeSlot)) {
          throw Exception('Time slot conflicts with existing schedule');
        }
        
        // Add the new time slot
        final updatedSchedule = daySchedule.addTimeSlot(timeSlot);
        
        // Update the document
        await dayDoc.set(updatedSchedule.toJson());
      } else {
        // Create new day schedule with the time slot
        final daySchedule = DaySchedule.empty(day).addTimeSlot(timeSlot);
        await dayDoc.set(daySchedule.toJson());
      }
    } catch (e) {
      throw Exception('Failed to add time slot: ${handleFirestoreError(e)}');
    }
  }

  /// Get schedule for a specific day
  Future<DaySchedule?> getDaySchedule(String semesterId, WeekDay day) async {
    ensureAuthenticated();
    
    try {
      final dayDoc = await _getTimetableCollection(semesterId).doc(day.name).get();
      
      if (!dayDoc.exists) {
        return null;
      }
      
      return DaySchedule.fromFirestore(dayDoc);
    } catch (e) {
      throw Exception('Failed to get day schedule: ${handleFirestoreError(e)}');
    }
  }

  /// Get full timetable for semester
  Future<TimeTable> getTimeTable(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getTimetableCollection(semesterId).get();
      
      final schedule = <WeekDay, List<TimeSlot>>{
        for (var day in WeekDay.values) day: <TimeSlot>[]
      };
      
      for (final doc in snapshot.docs) {
        final daySchedule = DaySchedule.fromFirestore(doc);
        schedule[daySchedule.day] = daySchedule.timeSlots;
      }
      
      final now = DateTime.now();
      return TimeTable(
        id: semesterId,
        schedule: schedule,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('Failed to get timetable: ${handleFirestoreError(e)}');
    }
  }

  /// Stream timetable for semester
  Stream<TimeTable> streamTimeTable(String semesterId) {
    return _getTimetableCollection(semesterId)
        .snapshots()
        .map((snapshot) {
      final schedule = <WeekDay, List<TimeSlot>>{
        for (var day in WeekDay.values) day: <TimeSlot>[]
      };
      
      for (final doc in snapshot.docs) {
        final daySchedule = DaySchedule.fromFirestore(doc);
        schedule[daySchedule.day] = daySchedule.timeSlots;
      }
      
      final now = DateTime.now();
      return TimeTable(
        id: semesterId,
        schedule: schedule,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  /// Remove a time slot from a day's schedule
  Future<void> removeTimeSlot(String semesterId, WeekDay day, String subjectId, String startTime) async {
    ensureAuthenticated();
    
    try {
      final dayDoc = _getTimetableCollection(semesterId).doc(day.name);
      final daySnapshot = await dayDoc.get();
      
      if (!daySnapshot.exists) {
        throw Exception('Day schedule not found');
      }
      
      final daySchedule = DaySchedule.fromFirestore(daySnapshot);
      final updatedSchedule = daySchedule.removeTimeSlot(subjectId, startTime);
      
      if (updatedSchedule.timeSlots.isEmpty) {
        // If no time slots left, delete the day document
        await dayDoc.delete();
      } else {
        // Update the document with remaining time slots
        await dayDoc.set(updatedSchedule.toJson());
      }
    } catch (e) {
      throw Exception('Failed to remove time slot: ${handleFirestoreError(e)}');
    }
  }

  /// Get all time slots for a semester (useful for analytics)
  Future<List<Map<String, dynamic>>> getAllTimeSlots(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getTimetableCollection(semesterId).get();
      final allSlots = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final daySchedule = DaySchedule.fromFirestore(doc);
        for (final slot in daySchedule.timeSlots) {
          allSlots.add({
            'day': daySchedule.day.name,
            'dayDisplayName': daySchedule.day.displayName,
            'subjectId': slot.subjectId,
            'startTime': slot.startTime,
            'endTime': slot.endTime,
            'room': slot.room,
            'updatedAt': daySchedule.updatedAt,
          });
        }
      }
      
      return allSlots;
    } catch (e) {
      throw Exception('Failed to get all time slots: ${handleFirestoreError(e)}');
    }
  }

  /// Check if a time slot conflicts with existing slots
  Future<bool> hasTimeConflict(String semesterId, WeekDay day, TimeSlot newSlot) async {
    ensureAuthenticated();
    
    try {
      final daySchedule = await getDaySchedule(semesterId, day);
      
      if (daySchedule == null) {
        return false; // No schedule for this day, so no conflicts
      }
      
      return daySchedule.hasTimeConflict(newSlot);
    } catch (e) {
      return false;
    }
  }

  /// Get total number of time slots across all days for a semester
  Future<int> getTimetableSlotCount(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final allSlots = await getAllTimeSlots(semesterId);
      return allSlots.length;
    } catch (e) {
      throw Exception('Failed to get timetable slot count: ${handleFirestoreError(e)}');
    }
  }

  /// Update multiple time slots for a day (batch operation)
  Future<void> updateDaySchedule(String semesterId, WeekDay day, List<TimeSlot> timeSlots) async {
    ensureAuthenticated();
    
    try {
      // Check if semester exists
      final semesterDoc = await _semestersCollection.doc(semesterId).get();
      if (!semesterDoc.exists) {
        throw Exception('Semester not found');
      }

      final dayDoc = _getTimetableCollection(semesterId).doc(day.name);
      
      if (timeSlots.isEmpty) {
        // If no time slots provided, delete the day document
        await dayDoc.delete();
      } else {
        // Sort time slots by start time
        timeSlots.sort((a, b) {
          final aMinutes = TimeSlot.timeToMinutes(a.startTime);
          final bMinutes = TimeSlot.timeToMinutes(b.startTime);
          return aMinutes.compareTo(bMinutes);
        });

        // Create or update day schedule
        final now = DateTime.now();
        final daySchedule = DaySchedule(
          day: day,
          timeSlots: timeSlots,
          createdAt: now,
          updatedAt: now,
        );
        
        await dayDoc.set(daySchedule.toJson());
      }
    } catch (e) {
      throw Exception('Failed to update day schedule: ${handleFirestoreError(e)}');
    }
  }

  /// Stream a specific day's schedule
  Stream<DaySchedule?> streamDaySchedule(String semesterId, WeekDay day) {
    return _getTimetableCollection(semesterId)
        .doc(day.name)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }
      return DaySchedule.fromFirestore(doc);
    });
  }

  /// Get subjects scheduled for a specific day
  Future<List<String>> getSubjectsForDay(String semesterId, WeekDay day) async {
    ensureAuthenticated();
    
    try {
      final daySchedule = await getDaySchedule(semesterId, day);
      
      if (daySchedule == null) {
        return [];
      }
      
      return daySchedule.timeSlots.map((slot) => slot.subjectId).toSet().toList();
    } catch (e) {
      throw Exception('Failed to get subjects for day: ${handleFirestoreError(e)}');
    }
  }

  /// Clear entire timetable for a semester
  Future<void> clearTimetable(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await _getTimetableCollection(semesterId).get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear timetable: ${handleFirestoreError(e)}');
    }
  }
}
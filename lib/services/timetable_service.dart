import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/timetable.dart';
import 'base_firestore_service.dart';

class TimetableService extends BaseFirestoreService {
  static const String _collection = 'timetables';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get timetable for a semester
  Future<TimeTable?> getTimetable(String semesterId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('semesterId', isEqualTo: semesterId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Create empty timetable if none exists
        return await _createEmptyTimetable(semesterId);
      }

      return TimeTable.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Failed to get timetable: $e');
    }
  }

  // Create empty timetable
  Future<TimeTable> _createEmptyTimetable(String semesterId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final timetableData = {
        'userId': user.uid,
        'semesterId': semesterId,
        'schedule': {
          for (var day in WeekDay.values) day.name: []
        },
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection(_collection).add(timetableData);
      
      return TimeTable(
        id: docRef.id,
        schedule: {for (var day in WeekDay.values) day: <TimeSlot>[]},
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('Failed to create empty timetable: $e');
    }
  }

  // Add time slot to timetable
  Future<void> addTimeSlot(String semesterId, WeekDay day, TimeSlot timeSlot) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final timetable = await getTimetable(semesterId);
      if (timetable == null) throw Exception('Timetable not found');

      // Check for overlaps
      final existingSlots = timetable.schedule[day] ?? [];
      for (final existingSlot in existingSlots) {
        if (timeSlot.overlapsWith(existingSlot)) {
          throw Exception('Time slot overlaps with existing slot: ${existingSlot.formattedTimeRange}');
        }
      }

      // Add the new slot
      final updatedSlots = [...existingSlots, timeSlot];
      updatedSlots.sort((a, b) => _timeToMinutes(a.startTime)
          .compareTo(_timeToMinutes(b.startTime)));

      final updatedSchedule = Map<WeekDay, List<TimeSlot>>.from(timetable.schedule);
      updatedSchedule[day] = updatedSlots;

      final updatedTimetable = timetable.copyWith(
        schedule: updatedSchedule,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(timetable.id)
          .update(updatedTimetable.toJson());

    } catch (e) {
      throw Exception('Failed to add time slot: $e');
    }
  }

  // Remove time slot from timetable
  Future<void> removeTimeSlot(String semesterId, WeekDay day, int slotIndex) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final timetable = await getTimetable(semesterId);
      if (timetable == null) throw Exception('Timetable not found');

      final existingSlots = List<TimeSlot>.from(timetable.schedule[day] ?? []);
      if (slotIndex < 0 || slotIndex >= existingSlots.length) {
        throw Exception('Invalid slot index');
      }

      existingSlots.removeAt(slotIndex);

      final updatedSchedule = Map<WeekDay, List<TimeSlot>>.from(timetable.schedule);
      updatedSchedule[day] = existingSlots;

      final updatedTimetable = timetable.copyWith(
        schedule: updatedSchedule,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(timetable.id)
          .update(updatedTimetable.toJson());

    } catch (e) {
      throw Exception('Failed to remove time slot: $e');
    }
  }

  // Update time slot in timetable
  Future<void> updateTimeSlot(String semesterId, WeekDay day, int slotIndex, TimeSlot updatedTimeSlot) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final timetable = await getTimetable(semesterId);
      if (timetable == null) throw Exception('Timetable not found');

      final existingSlots = List<TimeSlot>.from(timetable.schedule[day] ?? []);
      if (slotIndex < 0 || slotIndex >= existingSlots.length) {
        throw Exception('Invalid slot index');
      }

      // Check for overlaps with other slots (excluding the slot being updated)
      for (int i = 0; i < existingSlots.length; i++) {
        if (i != slotIndex && updatedTimeSlot.overlapsWith(existingSlots[i])) {
          throw Exception('Time slot overlaps with existing slot: ${existingSlots[i].formattedTimeRange}');
        }
      }

      existingSlots[slotIndex] = updatedTimeSlot;
      existingSlots.sort((a, b) => _timeToMinutes(a.startTime)
          .compareTo(_timeToMinutes(b.startTime)));

      final updatedSchedule = Map<WeekDay, List<TimeSlot>>.from(timetable.schedule);
      updatedSchedule[day] = existingSlots;

      final updatedTimetable = timetable.copyWith(
        schedule: updatedSchedule,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(timetable.id)
          .update(updatedTimetable.toJson());

    } catch (e) {
      throw Exception('Failed to update time slot: $e');
    }
  }

  // Delete entire timetable
  Future<void> deleteTimetable(String semesterId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('semesterId', isEqualTo: semesterId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete timetable: $e');
    }
  }

  // Helper method to convert time string to minutes
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }
}
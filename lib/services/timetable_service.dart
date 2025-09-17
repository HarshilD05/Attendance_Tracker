import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable.dart';
import 'base_firestore_service.dart';

class TimetableService extends BaseFirestoreService {
  static const String _semestersCollectionName = 'semesters';

  /// Get semesters collection reference
  CollectionReference get _semestersCollection => getCollection(_semestersCollectionName);

  /// Get timetable subcollection reference
  CollectionReference _getTimetableCollection(String semesterId) {
    return _semestersCollection.doc(semesterId).collection('timetable');
  }

  /// Add or update timetable slot
  Future<void> updateTimeTableSlot(String semesterId, String day, String timeSlot, String subjectId) async {
    ensureAuthenticated();
    
    try {
      // Check if semester exists
      final semesterDoc = await _semestersCollection.doc(semesterId).get();
      if (!semesterDoc.exists) {
        throw Exception('Semester not found');
      }

      await _getTimetableCollection(semesterId).doc('$day-$timeSlot').set({
        'day': day,
        'timeSlot': timeSlot,
        'subjectId': subjectId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update timetable slot: ${handleFirestoreError(e)}');
    }
  }

  /// Get timetable for a specific day
  Future<Map<String, String>> getDayTimetable(String semesterId, String day) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getTimetableCollection(semesterId)
          .where('day', isEqualTo: day)
          .get();
      
      final timetable = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        timetable[data['timeSlot']] = data['subjectId'];
      }
      
      return timetable;
    } catch (e) {
      throw Exception('Failed to get day timetable: ${handleFirestoreError(e)}');
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
        final data = doc.data() as Map<String, dynamic>;
        final dayString = data['day'] as String;
        final timeSlot = data['timeSlot'] as String;
        final subjectId = data['subjectId'] as String;
        
        // Parse timeSlot to get start and end times
        final timeParts = timeSlot.split('-');
        final startTime = timeParts[0];
        final endTime = timeParts.length > 1 ? timeParts[1] : startTime;
        
        final slot = TimeSlot(
          subjectId: subjectId,
          startTime: startTime,
          endTime: endTime,
        );
        
        // Add to appropriate day
        final weekDay = WeekDay.values.firstWhere(
          (day) => day.displayName.toLowerCase() == dayString.toLowerCase(),
          orElse: () => WeekDay.monday,
        );
        
        schedule[weekDay]!.add(slot);
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
        final data = doc.data() as Map<String, dynamic>;
        final dayString = data['day'] as String;
        final timeSlot = data['timeSlot'] as String;
        final subjectId = data['subjectId'] as String;
        
        // Parse timeSlot to get start and end times
        final timeParts = timeSlot.split('-');
        final startTime = timeParts[0];
        final endTime = timeParts.length > 1 ? timeParts[1] : startTime;
        
        final slot = TimeSlot(
          subjectId: subjectId,
          startTime: startTime,
          endTime: endTime,
        );
        
        // Add to appropriate day
        final weekDay = WeekDay.values.firstWhere(
          (day) => day.displayName.toLowerCase() == dayString.toLowerCase(),
          orElse: () => WeekDay.monday,
        );
        
        schedule[weekDay]!.add(slot);
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

  /// Remove timetable slot
  Future<void> removeTimeTableSlot(String semesterId, String day, String timeSlot) async {
    ensureAuthenticated();
    
    try {
      await _getTimetableCollection(semesterId).doc('$day-$timeSlot').delete();
    } catch (e) {
      throw Exception('Failed to remove timetable slot: ${handleFirestoreError(e)}');
    }
  }

  /// Get all time slots for a semester (useful for analytics)
  Future<List<Map<String, dynamic>>> getAllTimeSlots(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getTimetableCollection(semesterId).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'day': data['day'],
          'timeSlot': data['timeSlot'],
          'subjectId': data['subjectId'],
          'updatedAt': data['updatedAt'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all time slots: ${handleFirestoreError(e)}');
    }
  }

  /// Check if a time slot conflicts with existing slots
  Future<bool> hasTimeConflict(String semesterId, String day, String timeSlot, {String? excludeSlotId}) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getTimetableCollection(semesterId)
          .where('day', isEqualTo: day)
          .where('timeSlot', isEqualTo: timeSlot)
          .get();
      
      if (excludeSlotId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeSlotId);
      }
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get timetable slot count for a semester
  Future<int> getTimetableSlotCount(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getTimetableCollection(semesterId).get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get timetable slot count: ${handleFirestoreError(e)}');
    }
  }
}
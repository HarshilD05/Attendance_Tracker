import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/semester.dart';
import 'base_firestore_service.dart';
import 'user_service.dart';

class SemesterService extends BaseFirestoreService {
  static const String _collectionName = 'semesters';
  final UserService _userService = UserService();

  /// Get semesters collection reference
  CollectionReference get _semestersCollection => getCollection(_collectionName);

  /// Create a new semester
  Future<String> createSemester(Semester semester) async {
    ensureAuthenticated();
    
    try {
      // Create the semester document
      final docRef = await _semestersCollection.add(semester.toJson());
      
      // Add semester ID to user's semester list
      await _userService.addSemesterToUser(docRef.id);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create semester: ${handleFirestoreError(e)}');
    }
  }

  /// Get all semesters for current user
  Stream<List<Semester>> getUserSemesters() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _semestersCollection
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      // Sort client-side to avoid needing Firestore composite index
      final semesters = snapshot.docs
          .map((doc) => Semester.fromFirestore(doc))
          .toList();
      
      // Sort by createdAt descending (newest first)
      semesters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return semesters;
    });
  }

  /// Get a specific semester by ID
  Future<Semester?> getSemester(String semesterId) async {
    try {
      final doc = await _semestersCollection.doc(semesterId).get();
      if (doc.exists) {
        final semester = Semester.fromFirestore(doc);
        // Verify user ownership
        if (semester.userId != currentUserId) {
          throw Exception('Access denied: You do not own this semester');
        }
        return semester;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get semester: ${handleFirestoreError(e)}');
    }
  }

  /// Update a semester
  Future<void> updateSemester(Semester semester) async {
    ensureAuthenticated();
    
    try {
      if (semester.id == null) {
        throw Exception('Semester ID is required for updates');
      }
      
      // Verify user ownership
      final existingSemester = await getSemester(semester.id!);
      if (existingSemester == null) {
        throw Exception('Semester not found');
      }
      
      await _semestersCollection.doc(semester.id).update(semester.toJson());
    } catch (e) {
      throw Exception('Failed to update semester: ${handleFirestoreError(e)}');
    }
  }

  /// Delete a semester
  Future<void> deleteSemester(String semesterId) async {
    ensureAuthenticated();
    
    try {
      // Verify user ownership before deletion
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw Exception('Semester not found');
      }
      
      // Delete the semester document
      await _semestersCollection.doc(semesterId).delete();
      
      // Remove semester ID from user's semester list
      await _userService.removeSemesterFromUser(semesterId);
    } catch (e) {
      throw Exception('Failed to delete semester: ${handleFirestoreError(e)}');
    }
  }



  /// Add holiday to semester
  Future<void> addHolidayToSemester(String semesterId, DateTime holiday) async {
    ensureAuthenticated();
    
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw Exception('Semester not found');
      }

      final updatedHolidays = List<DateTime>.from(semester.holidayList);
      if (!updatedHolidays.any((h) => 
          h.year == holiday.year && 
          h.month == holiday.month && 
          h.day == holiday.day)) {
        updatedHolidays.add(holiday);
        updatedHolidays.sort();
      }
      
      final updatedSemester = semester.copyWith(holidayList: updatedHolidays);
      await updateSemester(updatedSemester);
    } catch (e) {
      throw Exception('Failed to add holiday: ${handleFirestoreError(e)}');
    }
  }

  /// Remove holiday from semester
  Future<void> removeHolidayFromSemester(String semesterId, DateTime holiday) async {
    ensureAuthenticated();
    
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw Exception('Semester not found');
      }

      final updatedHolidays = semester.holidayList
          .where((h) => !(h.year == holiday.year && 
                         h.month == holiday.month && 
                         h.day == holiday.day))
          .toList();
      
      final updatedSemester = semester.copyWith(holidayList: updatedHolidays);
      await updateSemester(updatedSemester);
    } catch (e) {
      throw Exception('Failed to remove holiday: ${handleFirestoreError(e)}');
    }
  }

  /// Get user's active semester (current date falls within semester dates)
  Future<Semester?> getActiveSemester() async {
    if (currentUserId == null) return null;

    try {
      final now = DateTime.now();
      
      // Get all user semesters and filter client-side to avoid composite index
      final snapshot = await _semestersCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (final doc in snapshot.docs) {
        final semester = Semester.fromFirestore(doc);
        if (now.isAfter(semester.semStartDate) && now.isBefore(semester.semEndDate)) {
          return semester;
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get active semester: ${handleFirestoreError(e)}');
    }
  }

  /// Check if semester name already exists for user
  Future<bool> semesterNameExists(String name, {String? excludeId}) async {
    if (currentUserId == null) return false;

    try {
      Query query = _semestersCollection
          .where('userId', isEqualTo: currentUserId)
          .where('name', isEqualTo: name);

      final snapshot = await query.get();
      
      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get semester statistics
  Future<Map<String, dynamic>> getSemesterStats(String semesterId) async {
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw Exception('Semester not found');
      }

      final now = DateTime.now();
      final totalDays = semester.durationInDays;
      final workingDays = semester.totalWorkingDays;
      final holidays = semester.holidayList.length;
      final subjectsSnapshot = await _semestersCollection.doc(semesterId).collection('subjects').count().get();
      final subjects = subjectsSnapshot.count ?? 0;
      
      // Calculate progress
      final daysPassed = now.isAfter(semester.semEndDate) 
          ? totalDays 
          : now.isBefore(semester.semStartDate) 
              ? 0 
              : now.difference(semester.semStartDate).inDays + 1;
              
      final progressPercentage = totalDays > 0 ? (daysPassed / totalDays * 100).clamp(0, 100) : 0;

      return {
        'totalDays': totalDays,
        'workingDays': workingDays,
        'holidays': holidays,
        'subjects': subjects,
        'daysPassed': daysPassed,
        'progressPercentage': progressPercentage.round(),
        'isActive': semester.isActive,
      };
    } catch (e) {
      throw Exception('Failed to get semester stats: ${handleFirestoreError(e)}');
    }
  }

  /// Update all holidays for a semester at once (more efficient than individual updates)
  Future<void> updateSemesterHolidays(String semesterId, List<DateTime> holidays) async {
    ensureAuthenticated();
    
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw Exception('Semester not found');
      }

      // Sort holidays chronologically
      final sortedHolidays = List<DateTime>.from(holidays);
      sortedHolidays.sort();
      
      final updatedSemester = semester.copyWith(holidayList: sortedHolidays);
      await updateSemester(updatedSemester);
    } catch (e) {
      throw Exception('Failed to update holidays: ${handleFirestoreError(e)}');
    }
  }


}

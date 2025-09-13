import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/semester.dart';
import '../models/subject.dart';
import '../models/timetable.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _semestersCollection => 
      _firestore.collection('semesters');

  // SEMESTER OPERATIONS

  // Create a new semester
  Future<String> createSemester(Semester semester) async {
    try {
      if (currentUserId == null) {
        throw 'User not authenticated';
      }

      final docRef = await _semestersCollection.add(semester.toJson());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create semester: $e';
    }
  }

  // Get all semesters for current user
  Stream<List<Semester>> getUserSemesters() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _semestersCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Semester.fromFirestore(doc))
          .toList();
    });
  }

  // Get a specific semester by ID
  Future<Semester?> getSemester(String semesterId) async {
    try {
      final doc = await _semestersCollection.doc(semesterId).get();
      if (doc.exists) {
        return Semester.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get semester: $e';
    }
  }

  // Update a semester
  Future<void> updateSemester(Semester semester) async {
    try {
      await _semestersCollection.doc(semester.id).update(semester.toJson());
    } catch (e) {
      throw 'Failed to update semester: $e';
    }
  }

  // Delete a semester
  Future<void> deleteSemester(String semesterId) async {
    try {
      await _semestersCollection.doc(semesterId).delete();
    } catch (e) {
      throw 'Failed to delete semester: $e';
    }
  }

  // SUBJECT OPERATIONS

  // Add subject to semester
  Future<void> addSubjectToSemester(String semesterId, Subject subject) async {
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw 'Semester not found';
      }

      final updatedSubjects = List<Subject>.from(semester.subjectList)
        ..add(subject);
      
      final updatedSemester = semester.copyWith(subjectList: updatedSubjects);
      await updateSemester(updatedSemester);
    } catch (e) {
      throw 'Failed to add subject: $e';
    }
  }

  // Remove subject from semester
  Future<void> removeSubjectFromSemester(String semesterId, String subjectId) async {
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw 'Semester not found';
      }

      final updatedSubjects = semester.subjectList
          .where((subject) => subject.id != subjectId)
          .toList();
      
      final updatedSemester = semester.copyWith(subjectList: updatedSubjects);
      await updateSemester(updatedSemester);
    } catch (e) {
      throw 'Failed to remove subject: $e';
    }
  }

  // Update subject in semester
  Future<void> updateSubjectInSemester(String semesterId, Subject updatedSubject) async {
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw 'Semester not found';
      }

      final updatedSubjects = semester.subjectList
          .map((subject) => subject.id == updatedSubject.id ? updatedSubject : subject)
          .toList();
      
      final updatedSemester = semester.copyWith(subjectList: updatedSubjects);
      await updateSemester(updatedSemester);
    } catch (e) {
      throw 'Failed to update subject: $e';
    }
  }

  // TIMETABLE OPERATIONS

  // Update timetable for semester
  Future<void> updateTimeTable(String semesterId, TimeTable timeTable) async {
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw 'Semester not found';
      }

      final updatedSemester = semester.copyWith(timeTable: timeTable);
      await updateSemester(updatedSemester);
    } catch (e) {
      throw 'Failed to update timetable: $e';
    }
  }

  // HOLIDAY OPERATIONS

  // Add holiday to semester
  Future<void> addHolidayToSemester(String semesterId, DateTime holiday) async {
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw 'Semester not found';
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
      throw 'Failed to add holiday: $e';
    }
  }

  // Remove holiday from semester
  Future<void> removeHolidayFromSemester(String semesterId, DateTime holiday) async {
    try {
      final semester = await getSemester(semesterId);
      if (semester == null) {
        throw 'Semester not found';
      }

      final updatedHolidays = semester.holidayList
          .where((h) => !(h.year == holiday.year && 
                         h.month == holiday.month && 
                         h.day == holiday.day))
          .toList();
      
      final updatedSemester = semester.copyWith(holidayList: updatedHolidays);
      await updateSemester(updatedSemester);
    } catch (e) {
      throw 'Failed to remove holiday: $e';
    }
  }

  // UTILITY METHODS

  // Get user's active semester (current date falls within semester dates)
  Future<Semester?> getActiveSemester() async {
    if (currentUserId == null) return null;

    try {
      final now = DateTime.now();
      final snapshot = await _semestersCollection
          .where('userId', isEqualTo: currentUserId)
          .where('semStartDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('semEndDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Semester.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw 'Failed to get active semester: $e';
    }
  }

  // Check if semester name already exists for user
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
}

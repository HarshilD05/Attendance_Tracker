import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import 'base_firestore_service.dart';

class SubjectService extends BaseFirestoreService {
  static const String _semestersCollectionName = 'semesters';

  /// Get semesters collection reference
  CollectionReference get _semestersCollection => getCollection(_semestersCollectionName);

  /// Get subjects subcollection reference
  CollectionReference _getSubjectsCollection(String semesterId) {
    return _semestersCollection.doc(semesterId).collection('subjects');
  }

  /// Add subject to semester subcollection
  Future<String> addSubject(String semesterId, Subject subject) async {
    ensureAuthenticated();
    
    try {
      // Check if semester exists
      final semesterDoc = await _semestersCollection.doc(semesterId).get();
      if (!semesterDoc.exists) {
        throw Exception('Semester not found');
      }

      final docRef = await _getSubjectsCollection(semesterId).add(subject.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add subject: ${handleFirestoreError(e)}');
    }
  }

  /// Get all subjects for a semester
  Future<List<Subject>> getSubjects(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getSubjectsCollection(semesterId)
          .orderBy('createdAt', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => Subject.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get subjects: ${handleFirestoreError(e)}');
    }
  }

  /// Stream subjects for a semester
  Stream<List<Subject>> streamSubjects(String semesterId) {
    return _getSubjectsCollection(semesterId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subject.fromFirestore(doc))
            .toList());
  }

  /// Get a specific subject
  Future<Subject?> getSubject(String semesterId, String subjectId) async {
    ensureAuthenticated();
    
    try {
      final doc = await _getSubjectsCollection(semesterId).doc(subjectId).get();
      if (!doc.exists) {
        return null;
      }
      return Subject.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get subject: ${handleFirestoreError(e)}');
    }
  }

  /// Update subject in semester subcollection
  Future<void> updateSubject(String semesterId, Subject updatedSubject) async {
    ensureAuthenticated();
    
    try {
      await _getSubjectsCollection(semesterId)
          .doc(updatedSubject.id)
          .update(updatedSubject.toJson());
    } catch (e) {
      throw Exception('Failed to update subject: ${handleFirestoreError(e)}');
    }
  }

  /// Remove subject from semester subcollection
  Future<void> removeSubject(String semesterId, String subjectId) async {
    ensureAuthenticated();
    
    try {
      await _getSubjectsCollection(semesterId).doc(subjectId).delete();
    } catch (e) {
      throw Exception('Failed to remove subject: ${handleFirestoreError(e)}');
    }
  }

  /// Get subject count for a semester
  Future<int> getSubjectCount(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getSubjectsCollection(semesterId).get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get subject count: ${handleFirestoreError(e)}');
    }
  }

  /// Check if subject name already exists in semester
  Future<bool> subjectNameExists(String semesterId, String subjectName, {String? excludeId}) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getSubjectsCollection(semesterId)
          .where('subjectName', isEqualTo: subjectName)
          .get();
      
      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';
import 'base_firestore_service.dart';

class AttendanceService extends BaseFirestoreService {
  static const String _semestersCollectionName = 'semesters';

  /// Get semesters collection reference
  CollectionReference get _semestersCollection => getCollection(_semestersCollectionName);

  /// Get attendance subcollection reference
  CollectionReference _getAttendanceCollection(String semesterId) {
    return _semestersCollection.doc(semesterId).collection('attendance');
  }

  /// Add attendance record
  Future<String> addAttendanceRecord(String semesterId, Attendance attendance) async {
    ensureAuthenticated();
    
    try {
      // Check if semester exists
      final semesterDoc = await _semestersCollection.doc(semesterId).get();
      if (!semesterDoc.exists) {
        throw Exception('Semester not found');
      }

      final docRef = await _getAttendanceCollection(semesterId).add(attendance.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add attendance record: ${handleFirestoreError(e)}');
    }
  }

  /// Get attendance records for a subject
  Future<List<Attendance>> getSubjectAttendance(String semesterId, String subjectId) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getAttendanceCollection(semesterId)
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('date', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => Attendance.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get subject attendance: ${handleFirestoreError(e)}');
    }
  }

  /// Get all attendance records for a semester
  Future<List<Attendance>> getSemesterAttendance(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getAttendanceCollection(semesterId)
          .orderBy('date', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => Attendance.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get semester attendance: ${handleFirestoreError(e)}');
    }
  }

  /// Stream attendance records for a subject
  Stream<List<Attendance>> streamSubjectAttendance(String semesterId, String subjectId) {
    return _getAttendanceCollection(semesterId)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Attendance.fromFirestore(doc))
            .toList());
  }

  /// Stream all attendance records for a semester
  Stream<List<Attendance>> streamSemesterAttendance(String semesterId) {
    return _getAttendanceCollection(semesterId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Attendance.fromFirestore(doc))
            .toList());
  }

  /// Update attendance record
  Future<void> updateAttendanceRecord(String semesterId, Attendance updatedAttendance) async {
    ensureAuthenticated();
    
    try {
      await _getAttendanceCollection(semesterId)
          .doc(updatedAttendance.id)
          .update(updatedAttendance.toJson());
    } catch (e) {
      throw Exception('Failed to update attendance record: ${handleFirestoreError(e)}');
    }
  }

  /// Delete attendance record
  Future<void> deleteAttendanceRecord(String semesterId, String attendanceId) async {
    ensureAuthenticated();
    
    try {
      await _getAttendanceCollection(semesterId).doc(attendanceId).delete();
    } catch (e) {
      throw Exception('Failed to delete attendance record: ${handleFirestoreError(e)}');
    }
  }

  /// Get attendance for a specific date
  Future<List<Attendance>> getDateAttendance(String semesterId, DateTime date) async {
    ensureAuthenticated();
    
    try {
      // Create date range for the entire day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _getAttendanceCollection(semesterId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      return snapshot.docs
          .map((doc) => Attendance.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get date attendance: ${handleFirestoreError(e)}');
    }
  }

  /// Get attendance for a date range
  Future<List<Attendance>> getDateRangeAttendance(String semesterId, DateTime startDate, DateTime endDate) async {
    ensureAuthenticated();
    
    try {
      final snapshot = await _getAttendanceCollection(semesterId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => Attendance.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get date range attendance: ${handleFirestoreError(e)}');
    }
  }

  /// Calculate attendance percentage for a subject
  Future<double> calculateSubjectAttendancePercentage(String semesterId, String subjectId) async {
    try {
      final attendanceRecords = await getSubjectAttendance(semesterId, subjectId);
      
      if (attendanceRecords.isEmpty) {
        return 0.0;
      }
      
      final presentCount = attendanceRecords.where((record) => record.present).length;
      return (presentCount / attendanceRecords.length) * 100;
    } catch (e) {
      throw Exception('Failed to calculate attendance percentage: ${handleFirestoreError(e)}');
    }
  }

  /// Calculate overall attendance percentage for semester
  Future<double> calculateSemesterAttendancePercentage(String semesterId) async {
    try {
      final attendanceRecords = await getSemesterAttendance(semesterId);
      
      if (attendanceRecords.isEmpty) {
        return 0.0;
      }
      
      final presentCount = attendanceRecords.where((record) => record.present).length;
      return (presentCount / attendanceRecords.length) * 100;
    } catch (e) {
      throw Exception('Failed to calculate semester attendance percentage: ${handleFirestoreError(e)}');
    }
  }

  /// Get attendance statistics for a subject
  Future<Map<String, dynamic>> getSubjectAttendanceStats(String semesterId, String subjectId) async {
    try {
      final attendanceRecords = await getSubjectAttendance(semesterId, subjectId);
      
      final totalClasses = attendanceRecords.length;
      final presentCount = attendanceRecords.where((record) => record.present).length;
      final absentCount = totalClasses - presentCount;
      final attendancePercentage = totalClasses > 0 ? (presentCount / totalClasses) * 100 : 0.0;
      
      // Calculate classes needed for 75% attendance
      final classesNeededFor75 = totalClasses > 0 
          ? ((0.75 * (totalClasses + 1)) - presentCount).ceil().clamp(0, double.infinity).toInt()
          : 0;
      
      return {
        'totalClasses': totalClasses,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'attendancePercentage': attendancePercentage.roundToDouble(),
        'classesNeededFor75': classesNeededFor75,
      };
    } catch (e) {
      throw Exception('Failed to get subject attendance stats: ${handleFirestoreError(e)}');
    }
  }

  /// Get attendance count for a specific date
  Future<int> getAttendanceCountForDate(String semesterId, DateTime date) async {
    ensureAuthenticated();
    
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _getAttendanceCollection(semesterId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get attendance count for date: ${handleFirestoreError(e)}');
    }
  }

  /// Check if attendance exists for subject on specific date
  Future<bool> attendanceExistsForDate(String semesterId, String subjectId, DateTime date) async {
    ensureAuthenticated();
    
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _getAttendanceCollection(semesterId)
          .where('subjectId', isEqualTo: subjectId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
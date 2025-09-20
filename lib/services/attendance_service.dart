import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';
import '../models/timetable.dart';
import 'base_firestore_service.dart';
import 'timetable_service.dart';
import 'semester_service.dart';

class AttendanceService extends BaseFirestoreService {
  static const String _collectionName = 'attendance';
  static const String _analysisDocName = 'attendance_analysis';
  
  final TimetableService _timetableService = TimetableService();
  final SemesterService _semesterService = SemesterService();

  CollectionReference get _attendanceCollection =>
      FirebaseFirestore.instance.collection('semesters');

  /// Get or create daily attendance for a specific date
  Future<DailyAttendance> getDailyAttendance(String semesterId, String date) async {
    ensureAuthenticated();
    
    try {
      final doc = await _attendanceCollection
          .doc(semesterId)
          .collection(_collectionName)
          .doc(date)
          .get();

      if (doc.exists) {
        return DailyAttendance.fromJson(
          doc.data() as Map<String, dynamic>,
          date,
          semesterId,
        );
      } else {
        // Create new daily attendance from timetable
        return await _createDailyAttendanceFromTimetable(semesterId, date);
      }
    } catch (e) {
      throw Exception('Failed to get daily attendance: ${handleFirestoreError(e)}');
    }
  }

  /// Create daily attendance from timetable for a specific date
  Future<DailyAttendance> _createDailyAttendanceFromTimetable(
    String semesterId, 
    String date,
  ) async {
    final dateTime = DateTime.parse(date);
    final weekDay = WeekDay.values[dateTime.weekday - 1];
    
    // Get timetable for the day
    final timetable = await _timetableService.getTimeTable(semesterId);
    final daySlots = timetable.schedule[weekDay] ?? [];
    
    // Create subject attendance entries
    final subjectAttendances = <String, SubjectAttendance>{};
    for (final slot in daySlots) {
      subjectAttendances[slot.subjectId] = SubjectAttendance(
        subjectId: slot.subjectId,
        status: AttendanceStatus.unmarked,
        startTime: slot.startTime,
        endTime: slot.endTime,
        roomNo: slot.room,
      );
    }
    
    final dailyAttendance = DailyAttendance(
      date: date,
      semesterId: semesterId,
      subjects: subjectAttendances,
      totalCredits: daySlots.length,
      creditsEarned: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Save to Firestore
    await _attendanceCollection
        .doc(semesterId)
        .collection(_collectionName)
        .doc(date)
        .set(dailyAttendance.toJson());
    
    return dailyAttendance;
  }

  /// Mark attendance for a specific subject on a specific date
  Future<void> markAttendance(
    String semesterId,
    String date,
    String subjectId,
    AttendanceStatus status,
  ) async {
    ensureAuthenticated();
    
    try {
      final dailyAttendance = await getDailyAttendance(semesterId, date);
      
      if (!dailyAttendance.subjects.containsKey(subjectId)) {
        throw Exception('Subject not found in daily attendance');
      }
      
      final currentSubject = dailyAttendance.subjects[subjectId]!;
      final updatedSubject = currentSubject.copyWith(status: status);
      
      // Calculate new credits earned
      final updatedSubjects = Map<String, SubjectAttendance>.from(dailyAttendance.subjects);
      updatedSubjects[subjectId] = updatedSubject;
      
      final creditsEarned = updatedSubjects.values
          .where((s) => s.status == AttendanceStatus.present)
          .length;
      
      final updatedDailyAttendance = dailyAttendance.copyWith(
        subjects: updatedSubjects,
        creditsEarned: creditsEarned,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore using batch
      final batch = FirebaseFirestore.instance.batch();
      
      // Update daily attendance
      batch.set(
        _attendanceCollection
            .doc(semesterId)
            .collection(_collectionName)
            .doc(date),
        updatedDailyAttendance.toJson(),
      );
      
      await batch.commit();
      
      // Update analysis asynchronously
      _updateAnalysisAfterAttendanceChange(semesterId);
      
    } catch (e) {
      throw Exception('Failed to mark attendance: ${handleFirestoreError(e)}');
    }
  }

  /// Get attendance for a date range
  Future<List<DailyAttendance>> getAttendanceRange(
    String semesterId,
    String startDate,
    String endDate,
  ) async {
    ensureAuthenticated();
    
    try {
      final query = await _attendanceCollection
          .doc(semesterId)
          .collection(_collectionName)
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDate)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endDate)
          .orderBy(FieldPath.documentId)
          .get();
      
      return query.docs.map((doc) => DailyAttendance.fromJson(
        doc.data(),
        doc.id,
        semesterId,
      )).toList();
    } catch (e) {
      throw Exception('Failed to get attendance range: ${handleFirestoreError(e)}');
    }
  }

  /// Check if a date is a holiday
  Future<bool> isHoliday(String semesterId, String date) async {
    try {
      final semester = await _semesterService.getSemester(semesterId);
      if (semester == null) return false;
      
      final dateTime = DateTime.parse(date);
      return semester.holidayList.any((holiday) =>
          holiday.year == dateTime.year &&
          holiday.month == dateTime.month &&
          holiday.day == dateTime.day);
    } catch (e) {
      return false;
    }
  }

  /// Get today's subjects with attendance status
  Future<List<SubjectAttendance>> getTodaysSubjects(String semesterId) async {
    final today = DateTime.now();
    final dateString = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    
    // Check if today is a holiday
    if (await isHoliday(semesterId, dateString)) {
      return []; // Return empty list for holidays
    }
    
    final dailyAttendance = await getDailyAttendance(semesterId, dateString);
    return dailyAttendance.subjects.values.toList();
  }

  /// Get subjects filtered by attendance status
  Future<List<SubjectAttendance>> getFilteredSubjects(
    String semesterId,
    String date,
    AttendanceStatus? filter,
  ) async {
    final dailyAttendance = await getDailyAttendance(semesterId, date);
    final subjects = dailyAttendance.subjects.values.toList();
    
    if (filter == null) {
      return subjects; // Return all subjects
    }
    
    return subjects.where((subject) => subject.status == filter).toList();
  }

  /// Update attendance analysis (run asynchronously)
  Future<void> _updateAnalysisAfterAttendanceChange(String semesterId) async {
    try {
      // Get all attendance records for the semester
      final attendanceRecords = await _attendanceCollection
          .doc(semesterId)
          .collection(_collectionName)
          .get();
      
      // Calculate subject-wise analysis
      final subjectAnalysis = <String, SubjectAnalysis>{};
      final monthlyData = <String, Map<String, int>>{}; // month -> {present: x, absent: y}
      
      int totalPresent = 0;
      int totalAbsent = 0;
      
      for (final doc in attendanceRecords.docs) {
        final dailyAttendance = DailyAttendance.fromJson(
          doc.data(),
          doc.id,
          semesterId,
        );
        
        final month = doc.id.substring(0, 7); // YYYY-MM
        monthlyData[month] ??= {'present': 0, 'absent': 0};
        
        for (final subjectAttendance in dailyAttendance.subjects.values) {
          final subjectId = subjectAttendance.subjectId;
          
          // Initialize subject analysis if not exists
          subjectAnalysis[subjectId] ??= SubjectAnalysis(
            subjectId: subjectId,
            allTimePercentage: 0.0,
            monthlyPercentage: {},
            totalLectures: 0,
            attendedLectures: 0,
            missableLectures: 0,
          );
          
          // Update counts based on status
          if (subjectAttendance.status == AttendanceStatus.present) {
            totalPresent++;
            monthlyData[month]!['present'] = monthlyData[month]!['present']! + 1;
          } else if (subjectAttendance.status == AttendanceStatus.absent) {
            totalAbsent++;
            monthlyData[month]!['absent'] = monthlyData[month]!['absent']! + 1;
          }
        }
      }
      
      // Calculate percentages and create analysis
      final monthlyAggregate = <String, MonthlyAggregate>{};
      for (final entry in monthlyData.entries) {
        final present = entry.value['present']!;
        final absent = entry.value['absent']!;
        final total = present + absent;
        final percentage = total > 0 ? (present / total * 100) : 0.0;
        
        monthlyAggregate[entry.key] = MonthlyAggregate(
          presentCount: present,
          absentCount: absent,
          percentage: percentage,
        );
      }
      
      final overallTotal = totalPresent + totalAbsent;
      final overallPercentage = overallTotal > 0 ? (totalPresent / overallTotal * 100) : 0.0;
      
      final analysis = AttendanceAnalysis(
        semesterId: semesterId,
        subjectWise: subjectAnalysis,
        monthlyAggregate: monthlyAggregate,
        overallAggregate: OverallAggregate(
          totalPresent: totalPresent,
          totalAbsent: totalAbsent,
          overallPercentage: overallPercentage,
        ),
        lastUpdated: DateTime.now(),
      );
      
      // Save analysis to Firestore
      await _attendanceCollection
          .doc(semesterId)
          .collection('analysis')
          .doc(_analysisDocName)
          .set(analysis.toJson());
      
    } catch (e) {
      // Log error but don't throw to avoid blocking attendance marking
      print('Error updating attendance analysis: $e');
    }
  }

  /// Get attendance analysis
  Future<AttendanceAnalysis> getAttendanceAnalysis(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final doc = await _attendanceCollection
          .doc(semesterId)
          .collection('analysis')
          .doc(_analysisDocName)
          .get();
      
      if (doc.exists) {
        return AttendanceAnalysis.fromJson(
          doc.data() as Map<String, dynamic>,
          semesterId,
        );
      } else {
        // Return empty analysis if not exists
        return AttendanceAnalysis.empty(semesterId);
      }
    } catch (e) {
      throw Exception('Failed to get attendance analysis: ${handleFirestoreError(e)}');
    }
  }

  /// Delete all attendance data for a semester
  Future<void> deleteAttendanceData(String semesterId) async {
    ensureAuthenticated();
    
    try {
      // Delete all daily attendance documents
      final attendanceDocs = await _attendanceCollection
          .doc(semesterId)
          .collection(_collectionName)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in attendanceDocs.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete analysis document
      batch.delete(
        _attendanceCollection
            .doc(semesterId)
            .collection('analysis')
            .doc(_analysisDocName),
      );
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete attendance data: ${handleFirestoreError(e)}');
    }
  }

  /// Get attendance summary for a specific date
  Future<Map<String, dynamic>> getAttendanceSummary(
    String semesterId,
    String date,
  ) async {
    final dailyAttendance = await getDailyAttendance(semesterId, date);
    
    return {
      'totalSubjects': dailyAttendance.totalCredits,
      'presentCount': dailyAttendance.presentCount,
      'absentCount': dailyAttendance.absentCount,
      'unmarkedCount': dailyAttendance.unmarkedCount,
      'attendancePercentage': dailyAttendance.attendancePercentage,
      'isFullyMarked': dailyAttendance.isFullyMarked,
    };
  }
}
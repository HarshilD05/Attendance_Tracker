import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  present,
  absent,
  unmarked;

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.unmarked:
        return 'Unmarked';
    }
  }
}

class SubjectAttendance {
  final String subjectId;
  final AttendanceStatus status;
  final String startTime;
  final String endTime;
  final String? roomNo;

  SubjectAttendance({
    required this.subjectId,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.roomNo,
  });

  factory SubjectAttendance.fromJson(Map<String, dynamic> json) {
    return SubjectAttendance(
      subjectId: json['subjectId'] as String,
      status: AttendanceStatus.values.firstWhere(
        (s) => s.name == json['status'] as String,
        orElse: () => AttendanceStatus.unmarked,
      ),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      roomNo: json['roomNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'status': status.name,
      'startTime': startTime,
      'endTime': endTime,
      if (roomNo != null) 'roomNo': roomNo,
    };
  }

  SubjectAttendance copyWith({
    String? subjectId,
    AttendanceStatus? status,
    String? startTime,
    String? endTime,
    String? roomNo,
  }) {
    return SubjectAttendance(
      subjectId: subjectId ?? this.subjectId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNo: roomNo ?? this.roomNo,
    );
  }
}

class DailyAttendance {
  final String date; // YYYY-MM-DD format
  final String semesterId;
  final Map<String, SubjectAttendance> subjects; // subjectId -> attendance
  final int totalCredits; // Total number of lectures for the day
  final int creditsEarned; // Number of lectures attended (present)
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyAttendance({
    required this.date,
    required this.semesterId,
    required this.subjects,
    required this.totalCredits,
    required this.creditsEarned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyAttendance.empty(String date, String semesterId) {
    final now = DateTime.now();
    return DailyAttendance(
      date: date,
      semesterId: semesterId,
      subjects: {},
      totalCredits: 0,
      creditsEarned: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DailyAttendance.fromJson(Map<String, dynamic> json, String date, String semesterId) {
    final subjectsJson = json['subjects'] as Map<String, dynamic>? ?? {};
    final subjects = <String, SubjectAttendance>{};
    
    for (final entry in subjectsJson.entries) {
      subjects[entry.key] = SubjectAttendance.fromJson(entry.value as Map<String, dynamic>);
    }

    return DailyAttendance(
      date: date,
      semesterId: semesterId,
      subjects: subjects,
      totalCredits: json['totalCredits'] as int? ?? 0,
      creditsEarned: json['creditsEarned'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    final subjectsJson = <String, dynamic>{};
    for (final entry in subjects.entries) {
      subjectsJson[entry.key] = entry.value.toJson();
    }

    return {
      'subjects': subjectsJson,
      'totalCredits': totalCredits,
      'creditsEarned': creditsEarned,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DailyAttendance copyWith({
    String? date,
    String? semesterId,
    Map<String, SubjectAttendance>? subjects,
    int? totalCredits,
    int? creditsEarned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyAttendance(
      date: date ?? this.date,
      semesterId: semesterId ?? this.semesterId,
      subjects: subjects ?? this.subjects,
      totalCredits: totalCredits ?? this.totalCredits,
      creditsEarned: creditsEarned ?? this.creditsEarned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  double get attendancePercentage {
    if (totalCredits == 0) return 0.0;
    return (creditsEarned / totalCredits * 100);
  }

  int get unmarkedCount {
    return subjects.values.where((s) => s.status == AttendanceStatus.unmarked).length;
  }

  int get presentCount {
    return subjects.values.where((s) => s.status == AttendanceStatus.present).length;
  }

  int get absentCount {
    return subjects.values.where((s) => s.status == AttendanceStatus.absent).length;
  }

  bool get isFullyMarked {
    return subjects.values.every((s) => s.status != AttendanceStatus.unmarked);
  }
}

// Analysis models for centralized statistics
class SubjectAnalysis {
  final String subjectId;
  final double allTimePercentage;
  final Map<String, double> monthlyPercentage; // 'YYYY-MM' -> percentage
  final int totalLectures;
  final int attendedLectures;
  final int missableLectures; // Can be missed to stay above 80%

  SubjectAnalysis({
    required this.subjectId,
    required this.allTimePercentage,
    required this.monthlyPercentage,
    required this.totalLectures,
    required this.attendedLectures,
    required this.missableLectures,
  });

  factory SubjectAnalysis.fromJson(Map<String, dynamic> json, String subjectId) {
    final monthlyJson = json['monthlyPercentage'] as Map<String, dynamic>? ?? {};
    final monthlyPercentage = <String, double>{};
    
    for (final entry in monthlyJson.entries) {
      monthlyPercentage[entry.key] = (entry.value as num).toDouble();
    }

    return SubjectAnalysis(
      subjectId: subjectId,
      allTimePercentage: (json['allTimePercentage'] as num?)?.toDouble() ?? 0.0,
      monthlyPercentage: monthlyPercentage,
      totalLectures: json['totalLectures'] as int? ?? 0,
      attendedLectures: json['attendedLectures'] as int? ?? 0,
      missableLectures: json['missableLectures'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allTimePercentage': allTimePercentage,
      'monthlyPercentage': monthlyPercentage,
      'totalLectures': totalLectures,
      'attendedLectures': attendedLectures,
      'missableLectures': missableLectures,
    };
  }
}

class MonthlyAggregate {
  final int presentCount;
  final int absentCount;
  final double percentage;

  MonthlyAggregate({
    required this.presentCount,
    required this.absentCount,
    required this.percentage,
  });

  factory MonthlyAggregate.fromJson(Map<String, dynamic> json) {
    return MonthlyAggregate(
      presentCount: json['presentCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'presentCount': presentCount,
      'absentCount': absentCount,
      'percentage': percentage,
    };
  }
}

class OverallAggregate {
  final int totalPresent;
  final int totalAbsent;
  final double overallPercentage;

  OverallAggregate({
    required this.totalPresent,
    required this.totalAbsent,
    required this.overallPercentage,
  });

  factory OverallAggregate.fromJson(Map<String, dynamic> json) {
    return OverallAggregate(
      totalPresent: json['totalPresent'] as int? ?? 0,
      totalAbsent: json['totalAbsent'] as int? ?? 0,
      overallPercentage: (json['overallPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPresent': totalPresent,
      'totalAbsent': totalAbsent,
      'overallPercentage': overallPercentage,
    };
  }
}

class AttendanceAnalysis {
  final String semesterId;
  final Map<String, SubjectAnalysis> subjectWise; // subjectId -> analysis
  final Map<String, MonthlyAggregate> monthlyAggregate; // 'YYYY-MM' -> aggregate
  final OverallAggregate overallAggregate;
  final DateTime lastUpdated;

  AttendanceAnalysis({
    required this.semesterId,
    required this.subjectWise,
    required this.monthlyAggregate,
    required this.overallAggregate,
    required this.lastUpdated,
  });

  factory AttendanceAnalysis.empty(String semesterId) {
    return AttendanceAnalysis(
      semesterId: semesterId,
      subjectWise: {},
      monthlyAggregate: {},
      overallAggregate: OverallAggregate(
        totalPresent: 0,
        totalAbsent: 0,
        overallPercentage: 0.0,
      ),
      lastUpdated: DateTime.now(),
    );
  }

  factory AttendanceAnalysis.fromJson(Map<String, dynamic> json, String semesterId) {
    final subjectWiseJson = json['subjectWise'] as Map<String, dynamic>? ?? {};
    final subjectWise = <String, SubjectAnalysis>{};
    
    for (final entry in subjectWiseJson.entries) {
      subjectWise[entry.key] = SubjectAnalysis.fromJson(
        entry.value as Map<String, dynamic>,
        entry.key,
      );
    }

    final monthlyJson = json['monthlyAggregate'] as Map<String, dynamic>? ?? {};
    final monthlyAggregate = <String, MonthlyAggregate>{};
    
    for (final entry in monthlyJson.entries) {
      monthlyAggregate[entry.key] = MonthlyAggregate.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return AttendanceAnalysis(
      semesterId: semesterId,
      subjectWise: subjectWise,
      monthlyAggregate: monthlyAggregate,
      overallAggregate: OverallAggregate.fromJson(
        json['overallAggregate'] as Map<String, dynamic>? ?? {},
      ),
      lastUpdated: (json['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final subjectWiseJson = <String, dynamic>{};
    for (final entry in subjectWise.entries) {
      subjectWiseJson[entry.key] = entry.value.toJson();
    }

    final monthlyJson = <String, dynamic>{};
    for (final entry in monthlyAggregate.entries) {
      monthlyJson[entry.key] = entry.value.toJson();
    }

    return {
      'subjectWise': subjectWiseJson,
      'monthlyAggregate': monthlyJson,
      'overallAggregate': overallAggregate.toJson(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
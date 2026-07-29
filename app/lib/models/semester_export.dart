import 'dart:convert';
import 'semester.dart';
import 'holiday.dart';
import 'subject.dart';

class SemesterExportData {
  final Semester semester;
  final List<Holiday> holidays;
  final List<Subject> subjects;
  
  // Format: "Monday" -> [{"subject_name": "Math", "start_time": "08:00", "end_time": "09:00", "class_room": "101"}]
  final Map<String, List<Map<String, dynamic>>> timetable;

  SemesterExportData({
    required this.semester,
    required this.holidays,
    required this.subjects,
    required this.timetable,
  });

  String toJsonString() {
    return jsonEncode({
      'name': semester.name,
      'start_date': semester.startDate,
      'end_date': semester.endDate,
      'min_attendance_req': semester.minAttendanceReq,
      'holidays': holidays.map((h) => {
        'date': h.date,
        'name': h.name,
      }).toList(),
      'subjects': subjects.map((s) => {
        'name': s.name,
        'teacher': s.teacher,
        'min_attendance_req': s.minAttendanceReq,
      }).toList(),
      'timetable': timetable,
    });
  }

  factory SemesterExportData.fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr);
    
    final semester = Semester(
      name: map['name'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      minAttendanceReq: (map['min_attendance_req'] as num?)?.toDouble() ?? 75.0,
    );

    final holidays = (map['holidays'] as List?)?.map((h) => Holiday(
      semId: 0, // Placeholder, will be set during import
      date: h['date'] as String,
      name: h['name'] as String,
    )).toList() ?? [];

    final subjects = (map['subjects'] as List?)?.map((s) => Subject(
      semId: 0, // Placeholder, will be set during import
      name: s['name'] as String,
      teacher: s['teacher'] as String?,
      minAttendanceReq: (s['min_attendance_req'] as num?)?.toDouble() ?? 75.0,
    )).toList() ?? [];

    final timetable = <String, List<Map<String, dynamic>>>{};
    if (map['timetable'] != null) {
      final rawTimetable = map['timetable'] as Map<String, dynamic>;
      for (final entry in rawTimetable.entries) {
        final day = entry.key;
        final slots = (entry.value as List).map((s) => Map<String, dynamic>.from(s)).toList();
        timetable[day] = slots;
      }
    }

    return SemesterExportData(
      semester: semester,
      holidays: holidays,
      subjects: subjects,
      timetable: timetable,
    );
  }
}

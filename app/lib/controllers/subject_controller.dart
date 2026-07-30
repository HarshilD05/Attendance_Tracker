import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../repositories/subject_repo.dart';

class SubjectController with ChangeNotifier {
  final SubjectRepo _subjectRepo = SubjectRepo();

  List<Subject> _subjects = [];

  List<Subject> get subjects => _subjects;

  Future<String?> loadSubjectsForSemester(int semId) async {
    try {
      _subjects = await _subjectRepo.getSubjectsForSemester(semId);
      notifyListeners();
      return null;
    } catch (e) {
  debugPrint("Error : $e");
      return 'Failed to load subjects.';
    }
  }

  Future<String?> addSubject(Subject subject) async {
    try {
      await _subjectRepo.insertSubject(subject);
      await loadSubjectsForSemester(subject.semId);
      return null;
    } catch (e) {
  debugPrint("Error : $e");
      return 'Failed to add subject.';
    }
  }

  Future<String?> removeSubject(int subjectId, int semId) async {
    try {
      await _subjectRepo.deleteSubject(subjectId);
      await loadSubjectsForSemester(semId);
      return null;
    } catch (e) {
  debugPrint("Error : $e");
      return 'Failed to delete subject.';
    }
  }
}

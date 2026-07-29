import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../repositories/subject_repo.dart';

class SubjectController with ChangeNotifier {
  final SubjectRepo _subjectRepo = SubjectRepo();

  List<Subject> _subjects = [];
  String? _errorMessage;

  List<Subject> get subjects => _subjects;
  String? get errorMessage => _errorMessage;

  Future<void> loadSubjectsForSemester(int semId) async {
    try {
      _errorMessage = null;
      _subjects = await _subjectRepo.getSubjectsForSemester(semId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load subjects: $e';
      notifyListeners();
    }
  }

  Future<void> addSubject(Subject subject) async {
    try {
      _errorMessage = null;
      await _subjectRepo.insertSubject(subject);
      await loadSubjectsForSemester(subject.semId);
    } catch (e) {
      _errorMessage = 'Failed to add subject: $e';
      notifyListeners();
    }
  }

  Future<void> removeSubject(int subjectId, int semId) async {
    try {
      _errorMessage = null;
      await _subjectRepo.deleteSubject(subjectId);
      await loadSubjectsForSemester(semId);
    } catch (e) {
      _errorMessage = 'Failed to delete subject: $e';
      notifyListeners();
    }
  }
}

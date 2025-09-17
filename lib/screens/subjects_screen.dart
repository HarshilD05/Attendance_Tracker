import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/subject_service.dart';
import '../theme/app_colors.dart';

class SubjectsScreen extends StatefulWidget {
  final String semesterId;
  
  const SubjectsScreen({
    super.key,
    required this.semesterId,
  });

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final SubjectService _subjectService = SubjectService();
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() => _isLoading = true);
      final subjects = await _subjectService.getSubjects(widget.semesterId);
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e')),
        );
      }
    }
  }

  void _showAddSubjectDialog() {
    _showSubjectDialog();
  }

  void _showEditSubjectDialog(Subject subject) {
    _showSubjectDialog(subject: subject);
  }

  void _showSubjectDialog({Subject? subject}) {
    final isEditing = subject != null;
    final nameController = TextEditingController(text: subject?.subjectName ?? '');
    final teacherController = TextEditingController(text: subject?.teacherName ?? '');
    final creditsController = TextEditingController(text: subject?.attendanceCredits.toString() ?? '1');
    bool hasLab = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Subject' : 'Add Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: teacherController,
                  decoration: const InputDecoration(
                    labelText: 'Teacher Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: creditsController,
                  decoration: const InputDecoration(
                    labelText: 'Attendance Credits *',
                    border: OutlineInputBorder(),
                    hintText: '1',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Has Lab Sessions:'),
                    const SizedBox(width: 8),
                    Radio<bool>(
                      value: false,
                      groupValue: hasLab,
                      onChanged: (value) {
                        setDialogState(() => hasLab = value!);
                      },
                    ),
                    const Text('Theory Only'),
                    Radio<bool>(
                      value: true,
                      groupValue: hasLab,
                      onChanged: (value) {
                        setDialogState(() => hasLab = value!);
                      },
                    ),
                    const Text('Theory + Lab'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _saveSubject(
                isEditing,
                subject?.id,
                nameController.text,
                teacherController.text,
                creditsController.text,
                hasLab,
              ),
              child: Text(isEditing ? 'Save' : 'Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSubject(
    bool isEditing,
    String? subjectId,
    String subjectName,
    String teacherName,
    String attendanceCredits,
    bool hasLab,
  ) async {
    if (subjectName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject name is required')),
      );
      return;
    }

    // Validate attendance credits
    int credits;
    try {
      credits = int.parse(attendanceCredits.trim());
      if (credits <= 0) {
        throw const FormatException('Credits must be positive');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid attendance credits (positive number)')),
      );
      return;
    }

    try {
      Navigator.pop(context); // Close dialog

      if (isEditing && subjectId != null) {
        // Update existing subject
        final updatedSubject = Subject(
          id: subjectId,
          subjectName: subjectName.trim(),
          teacherName: teacherName.trim().isEmpty ? null : teacherName.trim(),
          attendanceCredits: credits,
          createdAt: DateTime.now(),
        );
        
        await _subjectService.updateSubject(
          widget.semesterId,
          updatedSubject,
        );
      } else {
        // Add new subject(s) - Firestore will auto-generate document IDs
        final theorySubject = Subject(
          id: '', // Will be replaced with Firestore document ID 
          subjectName: subjectName.trim(),
          teacherName: teacherName.trim().isEmpty ? null : teacherName.trim(),
          attendanceCredits: credits,
          createdAt: DateTime.now(),
        );
        
        await _subjectService.addSubject(
          widget.semesterId,
          theorySubject,
        );

        // If has lab, create lab subject automatically
        if (hasLab) {
          final labSubject = Subject(
            id: '', // Will be replaced with Firestore document ID
            subjectName: '${subjectName.trim()}-LAB',
            teacherName: teacherName.trim().isEmpty ? null : teacherName.trim(),
            attendanceCredits: 2, // Lab gets 2 credits automatically
            createdAt: DateTime.now(),
          );
          
          await _subjectService.addSubject(
            widget.semesterId,
            labSubject,
          );
        }
      }

      await _loadSubjects();
      
      if (mounted) {
        final message = isEditing 
            ? 'Subject updated' 
            : hasLab 
                ? 'Theory and Lab subjects added'
                : 'Subject added';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving subject: $e')),
        );
      }
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.subjectName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _subjectService.removeSubject(
          widget.semesterId,
          subject.id,
        );
        await _loadSubjects();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting subject: $e')),
          );
        }
      }
    }
  }

  void _onSubjectLongPress(Subject subject) {
    setState(() {
      _selectedSubjectId = subject.id;
    });
    
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _selectedSubjectId = null;
        });
      }
    });
  }

  void _onSubjectTap() {
    setState(() {
      _selectedSubjectId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          IconButton(
            onPressed: _showAddSubjectDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Subject',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSubjects,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      return _buildSubjectCard(subject);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.subject_outlined,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Subjects Added',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subjects to start tracking attendance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddSubjectDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Subject'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    final isSelected = _selectedSubjectId == subject.id;
    
    return GestureDetector(
      onLongPress: () => _onSubjectLongPress(subject),
      onTap: _onSubjectTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  subject.subjectName.isNotEmpty 
                      ? subject.subjectName[0].toUpperCase() 
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                subject.subjectName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subject.teacherName != null)
                    Text('Teacher: ${subject.teacherName}'),
                  Text('Credits: ${subject.attendanceCredits}'),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                        onPressed: () => _showEditSubjectDialog(subject),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                        onPressed: () => _deleteSubject(subject),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
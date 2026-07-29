import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/semester_controller.dart';
import '../controllers/subject_controller.dart';
import '../models/subject.dart';
import '../widgets/custom_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/error_snackbar.dart';
import '../config/theme.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({Key? key}) : super(key: key);

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activeSem = Provider.of<SemesterController>(context, listen: false).activeSemester;
      if (activeSem != null) {
        final error = await Provider.of<SubjectController>(context, listen: false).loadSubjectsForSemester(activeSem.id!);
        if (error != null && mounted) {
          showErrorSnackBar(context, error);
        }
      }
    });
  }

  void _showAddSubjectModal(BuildContext context, int semId, double defaultMinReq) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();
    final reqCtrl = TextEditingController(text: defaultMinReq.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<AppColorScheme>()!.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 16, right: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add Subject', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: teacherCtrl,
                  decoration: const InputDecoration(labelText: 'Teacher Name (Optional)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reqCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Min Attendance %',
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Save Subject',
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final sub = Subject(
                        semId: semId,
                        name: nameCtrl.text,
                        teacher: teacherCtrl.text.trim().isEmpty ? null : teacherCtrl.text.trim(),
                        minAttendanceReq: double.tryParse(reqCtrl.text) ?? defaultMinReq,
                      );
                      final error = await Provider.of<SubjectController>(context, listen: false).addSubject(sub);
                      if (mounted) {
                        if (error != null) {
                          showErrorSnackBar(context, error);
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showSubjectDetailsPopup(Subject subject) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).extension<AppColorScheme>()!.surface,
          title: Text(subject.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subject.teacher != null) ...[
                Text('Teacher: ${subject.teacher}'),
                const SizedBox(height: 8),
              ],
              Text('Target Attendance: ${subject.minAttendanceReq.toStringAsFixed(0)}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            PrimaryButton(
              text: 'Delete',
              isDestructive: true,
              onPressed: () async {
                final error = await Provider.of<SubjectController>(context, listen: false).removeSubject(subject.id!, subject.semId);
                if (mounted) {
                  if (error != null) {
                    showErrorSnackBar(context, error);
                  } else {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = Provider.of<SemesterController>(context).activeSemester;
    final subjectController = Provider.of<SubjectController>(context);

    if (activeSem == null) {
      return Scaffold(appBar: AppBar(title: const Text('Error')), body: const Center(child: Text('No active semester')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: subjectController.subjects.isEmpty
          ? const Center(child: Text('No subjects added yet.'))
          : ListView.builder(
              itemCount: subjectController.subjects.length,
              itemBuilder: (context, index) {
                final sub = subjectController.subjects[index];
                return CustomCard(
                  onTap: () => _showSubjectDetailsPopup(sub),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.name, style: Theme.of(context).textTheme.titleLarge),
                      if (sub.teacher != null && sub.teacher!.isNotEmpty)
                        Text('Teacher: ${sub.teacher}', style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textSecondary)),
                      Text('Min: ${sub.minAttendanceReq.toStringAsFixed(0)}%', style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textMuted, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectModal(context, activeSem.id!, activeSem.minAttendanceReq),
        child: const Icon(Icons.add),
      ),
    );
  }
}

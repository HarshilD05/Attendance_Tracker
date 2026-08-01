import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';
import '../controllers/semester_controller.dart';
import '../widgets/custom_card.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/success_snackbar.dart';
import 'create_semester_screen.dart';
import 'semester_details_screen.dart';
import 'package:intl/intl.dart';
import '../models/semester.dart';

class SemestersScreen extends StatelessWidget {
  const SemestersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final semesterController = Provider.of<SemesterController>(context);
    final semesters = semesterController.semesters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semesters')
      ),
      body: semesters.isEmpty
          ? const Center(child: Text('No semesters found. Create one!'))
          : ListView.builder(
              itemCount: semesters.length,
              itemBuilder: (context, index) {
                final sem = semesters[index];
                return CustomCard(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    semesterController.setActiveSemester(sem);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SemesterDetailsScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sem.name, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    label: Text(sem.startDate, style: const TextStyle(fontSize: 12)),
                                    onPressed: null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    label: Text(sem.endDate, style: const TextStyle(fontSize: 12)),
                                    onPressed: null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditSemesterDialog(context, sem, semesterController),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSemesterScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditSemesterDialog(BuildContext context, Semester sem, SemesterController controller) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: sem.name);
    DateTime? startDate = DateFormat('yyyy-MM-dd').parse(sem.startDate);
    DateTime? endDate = DateFormat('yyyy-MM-dd').parse(sem.endDate);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Semester'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Semester Name'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(DateFormat('yyyy-MM-dd').format(startDate!), style: const TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: startDate!,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() => startDate = date);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(DateFormat('yyyy-MM-dd').format(endDate!), style: const TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: endDate!,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() => endDate = date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (endDate!.isBefore(startDate!)) {
                        showErrorSnackBar(context, 'End date must be after start date');
                        return;
                      }
                      HapticFeedback.mediumImpact();
                      final updatedSem = Semester(
                        id: sem.id,
                        name: nameCtrl.text,
                        startDate: DateFormat('yyyy-MM-dd').format(startDate!),
                        endDate: DateFormat('yyyy-MM-dd').format(endDate!),
                        minAttendanceReq: sem.minAttendanceReq,
                      );
                      final error = await controller.updateSemester(updatedSem);
                      if (ctx.mounted) {
                        if (error != null) {
                          showErrorSnackBar(ctx, error);
                        } else {
                          Navigator.pop(ctx);
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      }
    );
  }
}

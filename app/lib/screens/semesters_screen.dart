import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/semester_controller.dart';
import '../widgets/custom_card.dart';
import 'create_semester_screen.dart';
import 'semester_details_screen.dart';

class SemestersScreen extends StatelessWidget {
  const SemestersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final semesterController = Provider.of<SemesterController>(context);
    final semesters = semesterController.semesters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semesters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import JSON',
            onPressed: () => _showImportDialog(context, semesterController),
          ),
        ],
      ),
      body: semesters.isEmpty
          ? const Center(child: Text('No semesters found. Create one!'))
          : ListView.builder(
              itemCount: semesters.length,
              itemBuilder: (context, index) {
                final sem = semesters[index];
                return CustomCard(
                  onTap: () {
                    semesterController.setActiveSemester(sem);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SemesterDetailsScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sem.name, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('${sem.startDate} to ${sem.endDate}'),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: 'Export JSON',
                        onPressed: () async {
                          final jsonStr = await semesterController.exportSemester(sem.id!);
                          if (jsonStr != null && context.mounted) {
                            try {
                              final safeName = sem.name.replaceAll(' ', '_');
                              String? outputFile = await FilePicker.platform.saveFile(
                                dialogTitle: 'Save Semester JSON',
                                fileName: '$safeName.json',
                                type: FileType.custom,
                                allowedExtensions: ['json'],
                              );
                              if (outputFile != null) {
                                final file = File(outputFile);
                                await file.writeAsString(jsonStr);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved to $outputFile')),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to export file')),
                                );
                              }
                            }
                          }
                        },
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

  Future<void> _showImportDialog(BuildContext context, SemesterController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        final error = await controller.importSemester(jsonStr);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Semester imported successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Semester JSON format')),
        );
      }
    }
  }
}

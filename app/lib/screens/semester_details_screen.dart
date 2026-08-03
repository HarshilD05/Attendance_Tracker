import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../controllers/semester_controller.dart';
import '../widgets/primary_button.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/success_snackbar.dart';
import 'subjects_screen.dart';
import 'holidays_screen.dart';
import 'timetable_setup_screen.dart';
import '../config/theme.dart';

class SemesterDetailsScreen extends StatelessWidget {
  const SemesterDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeSem = Provider.of<SemesterController>(context).activeSemester;

    if (activeSem == null) {
      return Scaffold(appBar: AppBar(title: const Text('Error')), body: const Center(child: Text('No active semester')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activeSem.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Export JSON',
            onPressed: () {
              final controller = Provider.of<SemesterController>(context, listen: false);
              _exportSemester(context, controller, activeSem.id!, activeSem.name);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      activeSem.startDate,
                      style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textSecondary),
                    ),
                    onPressed: null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      activeSem.endDate,
                      style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textSecondary),
                    ),
                    onPressed: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
              child: Text(
                'MANAGE',
                style: TextStyle(
                  color: Theme.of(context).extension<AppColorScheme>()!.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.menu_book),
              label: const Text('Subjects', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).extension<AppColorScheme>()!.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectsScreen()));
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).extension<AppColorScheme>()!.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidaysScreen()));
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.beach_access, size: 36),
                          SizedBox(height: 8),
                          Text('Holidays', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).extension<AppColorScheme>()!.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableSetupScreen()));
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, size: 36),
                          SizedBox(height: 8),
                          Text('Timetable', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Delete Semester',
              isDestructive: true,
              onPressed: () => _confirmDelete(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final activeSem = Provider.of<SemesterController>(context, listen: false).activeSemester;
    if (activeSem == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Semester'),
        content: Text(
          'Permanently delete "${activeSem.name}"?\n\nAll subjects, timetable slots, holidays, and attendance records for this semester will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              final controller = Provider.of<SemesterController>(context, listen: false);
              final error = await controller.deleteSemester(activeSem.id!);
              if (context.mounted) {
                if (error != null) {
                  showErrorSnackBar(context, error);
                } else {
                  // Pop back to the Semesters list
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSemester(
    BuildContext context,
    SemesterController controller,
    int semId,
    String semName,
  ) async {
    final jsonStr = await controller.exportSemester(semId);
    if (jsonStr == null) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Export failed: could not build semester data.');
      }
      return;
    }

    final safeName = semName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final fileName = '$safeName.json';
    final fileData = Uint8List.fromList(utf8.encode(jsonStr));

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use flutter_file_dialog for mobile (SAF on Android, DocumentPicker on iOS)
        // We write to a temporary file first, which the plugin then copies using ContentResolver
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(fileData);

        final params = SaveFileDialogParams(sourceFilePath: tempFile.path, fileName: fileName);
        final resultPath = await FlutterFileDialog.saveFile(params: params);

        if (resultPath != null && context.mounted) {
          showSuccessSnackBar(context, 'Semester exported successfully!');
        }
      } else {
        // Desktop: show a native save-file dialog.
        final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
        if (result != null) {
          final XFile xFile = XFile.fromData(
            fileData,
            mimeType: 'application/json',
            name: fileName,
          );
          await xFile.saveTo(result.path);

          if (context.mounted) {
            showSuccessSnackBar(context, 'Saved: ${result.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      if (context.mounted) {
        showErrorSnackBar(context, 'Export failed.');
      }
    }
  }
}

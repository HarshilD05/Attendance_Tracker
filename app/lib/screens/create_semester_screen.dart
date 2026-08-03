import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import '../controllers/semester_controller.dart';
import '../models/semester.dart';
import '../widgets/primary_button.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/success_snackbar.dart';
import 'semester_details_screen.dart';

class CreateSemesterScreen extends StatefulWidget {
  const CreateSemesterScreen({super.key});

  @override
  State<CreateSemesterScreen> createState() => _CreateSemesterScreenState();
}

class _CreateSemesterScreenState extends State<CreateSemesterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minReqController = TextEditingController(text: '75');
  DateTime? _startDate;
  DateTime? _endDate;

  void _saveSemester() async {
    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        showErrorSnackBar(context, 'End date must be after start date');
        return;
      }

      final format = DateFormat('yyyy-MM-dd');
      final minReq = double.tryParse(_minReqController.text) ?? 75.0;
      final newSem = Semester(
        name: _nameController.text,
        startDate: format.format(_startDate!),
        endDate: format.format(_endDate!),
        minAttendanceReq: minReq,
      );

      final error = await Provider.of<SemesterController>(context, listen: false).createSemester(newSem);
      if (!mounted) return;
      if (error != null) {
        showErrorSnackBar(context, error);
      } else {
        showSuccessSnackBar(context, 'Semester created successfully!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SemesterDetailsScreen()),
        );
      }
    } else {
      showErrorSnackBar(context, 'Please fill all fields and select dates');
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Semester'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Import JSON',
            onPressed: () {
              final controller = Provider.of<SemesterController>(context, listen: false);
              _importSemester(context, controller);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Semester Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate == null ? 'Start Date' : format.format(_startDate!)),
                      onPressed: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate == null ? 'End Date' : format.format(_endDate!)),
                      onPressed: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minReqController,
                decoration: const InputDecoration(
                  labelText: 'Min Attendance % (default for all subjects)',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  final d = double.tryParse(val);
                  if (d == null || d < 0 || d > 100) return 'Enter a value between 0 and 100';
                  return null;
                },
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Save Semester',
                onPressed: _saveSemester,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importSemester(BuildContext context, SemesterController controller) async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'JSON',
        extensions: <String>['json'],
        mimeTypes: <String>['application/json'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (file != null) {
        final jsonStr = await file.readAsString();
        final error = await controller.importSemester(jsonStr);

        if (!context.mounted) return;
        
        if (error != null) {
          showErrorSnackBar(context, error);
        } else {
          showSuccessSnackBar(context, 'Semester imported successfully!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SemesterDetailsScreen()),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      showErrorSnackBar(context, 'Failed to read file. Ensure it is a valid semester JSON.');
    }
  }
}

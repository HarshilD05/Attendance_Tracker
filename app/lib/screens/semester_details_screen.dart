import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/semester_controller.dart';
import '../widgets/primary_button.dart';
import 'subjects_screen.dart';
import 'holidays_screen.dart';
import 'timetable_setup_screen.dart';

class SemesterDetailsScreen extends StatelessWidget {
  const SemesterDetailsScreen({Key? key}) : super(key: key);

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
              // TODO: Implement JSON Export logic
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dates: ${activeSem.startDate} to ${activeSem.endDate}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Manage Subjects',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectsScreen()));
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Manage Holidays',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidaysScreen()));
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Manage Timetable',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableSetupScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
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
                            const SizedBox(height: 8),
                            Text('${sem.startDate} to ${sem.endDate}'),
                          ],
                        ),
                      )
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
}

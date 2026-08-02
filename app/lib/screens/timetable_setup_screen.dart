import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/semester_controller.dart';
import '../controllers/timetable_controller.dart';
import '../controllers/subject_controller.dart';
import '../models/timetable_slot.dart';
import '../models/subject.dart';
import '../widgets/add_slot_modal.dart';
import '../widgets/timetable_setup_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/error_snackbar.dart';
import '../config/theme.dart';

class TimetableSetupScreen extends StatefulWidget {
  const TimetableSetupScreen({Key? key}) : super(key: key);

  @override
  State<TimetableSetupScreen> createState() => _TimetableSetupScreenState();
}

class _TimetableSetupScreenState extends State<TimetableSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Update selectedDayOfWeek when tab changes (in-memory only, no DB call)
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        Provider.of<TimetableController>(context, listen: false)
            .setSelectedDay(_tabController.index + 1);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeSem =
          Provider.of<SemesterController>(context, listen: false).activeSemester;
      if (activeSem != null) {
        // Load subjects for the dropdown
        Provider.of<SubjectController>(context, listen: false)
            .loadSubjectsForSemester(activeSem.id!);
        // Preload ALL days at once
        Provider.of<TimetableController>(context, listen: false)
            .loadAllTimetable(activeSem.id!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSlotModal(int semId, int dayOfWeek, List<Subject> subjects) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please add Subjects first!')));
      return;
    }
    final tc = Provider.of<TimetableController>(context, listen: false);
    showAddSlotModal(
      context: context,
      semId: semId,
      dayOfWeek: dayOfWeek,
      subjects: subjects,
      existingSlots: tc.slotsByDay[dayOfWeek] ?? [],
      onSave: (slot) async {
        final error = await tc.addSlot(slot);
        return error;
      },
    );
  }

  void _showSlotDetails(TimetableSlot slot, String subjectName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              Theme.of(context).extension<AppColorScheme>()!.surface,
          title: Text(subjectName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: ${slot.startTime} - ${slot.endTime}'),
              if (slot.classRoom.isNotEmpty) Text('Classroom: ${slot.classRoom}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            PrimaryButton(
              text: 'Remove Slot',
              isDestructive: true,
              onPressed: () async {
                HapticFeedback.heavyImpact();
                final error = await Provider.of<TimetableController>(
                        context,
                        listen: false)
                    .removeSlot(slot.slotId!, slot.semId);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem =
        Provider.of<SemesterController>(context).activeSemester;
    final tc = Provider.of<TimetableController>(context);
    final sc = Provider.of<SubjectController>(context);

    if (activeSem == null) return const Scaffold();

    final subjectMap = {for (var s in sc.subjects) s.id!: s.name};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Setup'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
      ),
      body: tc.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(6, (tabIndex) {
                final dayOfWeek = tabIndex + 1;
                final daySlots = tc.slotsByDay[dayOfWeek] ?? [];

                if (daySlots.isEmpty) {
                  return const Center(
                      child: Text('No classes scheduled for this day.'));
                }

                return ListView.builder(
                  itemCount: daySlots.length,
                  itemBuilder: (context, index) {
                    final slot = daySlots[index];
                    final subName =
                        subjectMap[slot.subId] ?? 'Unknown Subject';

                    final format24 = DateFormat('HH:mm');
                    final format12 = DateFormat.jm();

                    String displayTime = '';
                    try {
                      final st = format24.parse(slot.startTime);
                      final et = format24.parse(slot.endTime);
                      displayTime =
                          '${format12.format(st)} - ${format12.format(et)}';
                    } catch (e) {
                      debugPrint('TimetableSetup time parse error: $e');
                      displayTime = '${slot.startTime} - ${slot.endTime}';
                    }

                    return TimetableSetupCard(
                      slot: slot,
                      subName: subName,
                      displayTime: displayTime,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showSlotDetails(slot, subName);
                      },
                    );
                  },
                );
              }),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddSlotModal(activeSem.id!, tc.selectedDayOfWeek, sc.subjects),
        child: const Icon(Icons.add),
      ),
    );
  }
}

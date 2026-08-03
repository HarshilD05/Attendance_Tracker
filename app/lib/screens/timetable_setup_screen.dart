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
import '../widgets/error_snackbar.dart';

class TimetableSetupScreen extends StatefulWidget {
  const TimetableSetupScreen({super.key});

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

  void _confirmDeleteSlot(BuildContext context, TimetableSlot slot, String subName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text('Are you sure you want to remove the slot for $subName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              final error = await Provider.of<TimetableController>(context, listen: false).removeSlot(slot.slotId!, slot.semId);
              if (!context.mounted) return;
              if (error != null) {
                showErrorSnackBar(context, error);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
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
                  padding: const EdgeInsets.only(bottom: 84),
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
                      onDelete: () {
                        HapticFeedback.lightImpact();
                        _confirmDeleteSlot(context, slot, subName);
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

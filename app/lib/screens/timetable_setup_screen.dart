import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/semester_controller.dart';
import '../controllers/timetable_controller.dart';
import '../controllers/subject_controller.dart';
import '../models/timetable_slot.dart';
import '../models/subject.dart';
import '../widgets/custom_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/error_snackbar.dart';
import '../config/theme.dart';

class TimetableSetupScreen extends StatefulWidget {
  const TimetableSetupScreen({Key? key}) : super(key: key);

  @override
  State<TimetableSetupScreen> createState() => _TimetableSetupScreenState();
}

class _TimetableSetupScreenState extends State<TimetableSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadSlotsForSelectedTab();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeSem = Provider.of<SemesterController>(context, listen: false).activeSemester;
      if (activeSem != null) {
        // Load subjects for the dropdown
        Provider.of<SubjectController>(context, listen: false).loadSubjectsForSemester(activeSem.id!);
        // Load initial timetable for Monday (dayOfWeek = 1)
        Provider.of<TimetableController>(context, listen: false).setSelectedDay(1, activeSem.id!);
      }
    });
  }
  
  void _loadSlotsForSelectedTab() {
    final activeSem = Provider.of<SemesterController>(context, listen: false).activeSemester;
    if (activeSem != null) {
      final dayOfWeek = _tabController.index + 1; // 1=Mon, 6=Sat
      Provider.of<TimetableController>(context, listen: false).setSelectedDay(dayOfWeek, activeSem.id!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSlotModal(int semId, int dayOfWeek, List<Subject> subjects) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add Subjects first!')));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final classroomCtrl = TextEditingController();
    Subject? selectedSubject = subjects.first;
    
    final tc = Provider.of<TimetableController>(context, listen: false);
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    
    if (tc.slots.isNotEmpty) {
      TimeOfDay maxEndTime = const TimeOfDay(hour: 0, minute: 0);
      for (var slot in tc.slots) {
        final parts = slot.endTime.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          if (h > maxEndTime.hour || (h == maxEndTime.hour && m > maxEndTime.minute)) {
            maxEndTime = TimeOfDay(hour: h, minute: m);
          }
        }
      }
      if (maxEndTime.hour != 0 || maxEndTime.minute != 0) {
        startTime = maxEndTime;
      }
    }
    
    TimeOfDay endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<AppColorScheme>()!.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            Future<void> pickTime(bool isStart) async {
              final time = await showTimePicker(
                context: context,
                initialTime: isStart ? startTime : endTime,
              );
              if (time != null) {
                setModalState(() {
                  if (isStart) {
                    startTime = time;
                    endTime = TimeOfDay(hour: (time.hour + 1) % 24, minute: time.minute);
                  } else {
                    endTime = time;
                  }
                });
              }
            }

            // Helper to format TimeOfDay to HH:mm string (24 hour format for sorting/db)
            String formatTimeOfDay(TimeOfDay tod) {
              final now = DateTime.now();
              final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
              return DateFormat('HH:mm').format(dt);
            }
            
            // Helper for display (12 hour)
            String displayTimeOfDay(TimeOfDay tod) {
              final now = DateTime.now();
              final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
              return DateFormat.jm().format(dt);
            }

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
                    Text('Add Timetable Slot', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Subject>(
                      value: selectedSubject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map((sub) {
                        return DropdownMenuItem(value: sub, child: Text(sub.name));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedSubject = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(displayTimeOfDay(startTime)),
                            onPressed: () => pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(displayTimeOfDay(endTime)),
                            onPressed: () => pickTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: classroomCtrl,
                      decoration: const InputDecoration(labelText: 'Classroom (Optional)'),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Save Slot',
                      onPressed: () async {
                        final slot = TimetableSlot(
                          semId: semId,
                          subId: selectedSubject!.id!,
                          dayOfWeek: dayOfWeek,
                          startTime: formatTimeOfDay(startTime),
                          endTime: formatTimeOfDay(endTime),
                          classRoom: classroomCtrl.text,
                        );

                        final tc = Provider.of<TimetableController>(context, listen: false);
                        final error = await tc.addSlot(slot);
                        
                        if (mounted) {
                          if (error != null) {
                            showErrorSnackBar(context, error);
                          } else {
                            Navigator.pop(context);
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
    );
  }

  void _showSlotDetails(TimetableSlot slot, String subjectName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).extension<AppColorScheme>()!.surface,
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
                final error = await Provider.of<TimetableController>(context, listen: false).removeSlot(slot.slotId!, slot.semId);
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
    final tc = Provider.of<TimetableController>(context);
    final sc = Provider.of<SubjectController>(context);

    if (activeSem == null) return const Scaffold();

    // Map subject IDs to names for quick display
    final subjectMap = { for (var s in sc.subjects) s.id! : s.name };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Setup'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days.map((_) {
          if (tc.slots.isEmpty) {
            return const Center(child: Text('No classes scheduled for this day.'));
          }
          
          return ListView.builder(
            itemCount: tc.slots.length,
            itemBuilder: (context, index) {
              final slot = tc.slots[index];
              final subName = subjectMap[slot.subId] ?? 'Unknown Subject';
              
              // Formatting time for display (converting 24h to 12h)
              final format24 = DateFormat('HH:mm');
              final format12 = DateFormat.jm();
              
              String displayTime = '';
              try {
                final st = format24.parse(slot.startTime);
                final et = format24.parse(slot.endTime);
                displayTime = '${format12.format(st)} - ${format12.format(et)}';
              } catch (e) {
  print(e);
                displayTime = '${slot.startTime} - ${slot.endTime}';
              }

              return CustomCard(
                onTap: () => _showSlotDetails(slot, subName),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(displayTime, style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textSecondary)),
                      ],
                    ),
                    if (slot.classRoom.isNotEmpty)
                      Chip(label: Text(slot.classRoom, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSlotModal(activeSem.id!, tc.selectedDayOfWeek, sc.subjects),
        child: const Icon(Icons.add),
      ),
    );
  }
}

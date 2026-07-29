import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/semester_controller.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/subject_controller.dart';
import '../widgets/custom_card.dart';
import '../widgets/error_snackbar.dart';
import '../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final activeSem = Provider.of<SemesterController>(context, listen: false).activeSemester;
    if (activeSem != null) {
      final ac = Provider.of<AttendanceController>(context, listen: false);
      ac.setSelectedDate(ac.selectedDate, activeSem.id!);
      Provider.of<SubjectController>(context, listen: false).loadSubjectsForSemester(activeSem.id!);
    }
  }

  Future<void> _pickDate(BuildContext context, int semId, AttendanceController ac) async {
    final date = await showDatePicker(
      context: context,
      initialDate: ac.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      ac.setSelectedDate(date, semId);
    }
  }

  void _markAttendance(int semId, int subId, int? slotId, String studentStatus, AttendanceController ac) async {
    final error = await ac.markAttendance(semId, subId, slotId, 'Conducted', studentStatus);
    if (error != null && mounted) {
      showErrorSnackBar(context, error);
    }
  }

  void _markAll(int semId, String studentStatus, AttendanceController ac) async {
    final error = await ac.markAllAttendance(semId, ac.todaysSchedule, studentStatus);
    if (error != null && mounted) {
      showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = Provider.of<SemesterController>(context).activeSemester;
    final ac = Provider.of<AttendanceController>(context);
    final sc = Provider.of<SubjectController>(context);

    if (activeSem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('No active semester. Please select or create one from the Semesters tab.')),
      );
    }

    final format12 = DateFormat.jm();
    final format24 = DateFormat('HH:mm');
    final displayDate = DateFormat('EEE, MMM d').format(ac.selectedDate);

    final subjectMap = { for (var s in sc.subjects) s.id! : s };
    final attendanceMap = { for (var a in ac.todaysAttendance) a.slotId : a };

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => ac.setSelectedDate(ac.selectedDate.subtract(const Duration(days: 1)), activeSem.id!),
            ),
            Text(displayDate),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => ac.setSelectedDate(ac.selectedDate.add(const Duration(days: 1)), activeSem.id!),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _pickDate(context, activeSem.id!, ac),
          )
        ],
      ),
      body: ac.todaysSchedule.isEmpty
          ? const Center(child: Text('No classes scheduled for today.'))
          : Column(
              children: [
                // ── All Present / All Absent quick bar ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickMarkButton(
                          label: 'All Present',
                          icon: Icons.check_circle_outline,
                          color: AppTheme.presentColor,
                          onTap: () => _markAll(activeSem.id!, 'P', ac),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickMarkButton(
                          label: 'All Absent',
                          icon: Icons.cancel_outlined,
                          color: AppTheme.absentColor,
                          onTap: () => _markAll(activeSem.id!, 'A', ac),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Slot list ───────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    itemCount: ac.todaysSchedule.length,
                    itemBuilder: (context, index) {
                      final slot = ac.todaysSchedule[index];
                      final subject = subjectMap[slot.subId];
                      final subName = subject?.name ?? 'Unknown Subject';

                      String displayTime = '';
                      try {
                        final st = format24.parse(slot.startTime);
                        final et = format24.parse(slot.endTime);
                        displayTime = '${format12.format(st)} - ${format12.format(et)}';
                      } catch (e) {
                        displayTime = '${slot.startTime} - ${slot.endTime}';
                      }

                      final existingAttendance = attendanceMap[slot.slotId];
                      final isPresent = existingAttendance?.studentStatus == 'P';
                      final isAbsent = existingAttendance?.studentStatus == 'A';

                      return CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(subName, style: Theme.of(context).textTheme.titleLarge),
                                if (slot.classRoom.isNotEmpty)
                                  Chip(label: Text(slot.classRoom, style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(displayTime, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPresent ? Colors.green : AppTheme.surface,
                                      foregroundColor: isPresent ? Colors.white : Colors.white70,
                                      side: BorderSide(color: isPresent ? Colors.green : Colors.white24),
                                    ),
                                    onPressed: () => _markAttendance(activeSem.id!, slot.subId, slot.slotId, 'P', ac),
                                    child: const Text('Present'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isAbsent ? AppTheme.absentColor : AppTheme.surface,
                                      foregroundColor: isAbsent ? Colors.white : Colors.white70,
                                      side: BorderSide(color: isAbsent ? AppTheme.absentColor : Colors.white24),
                                    ),
                                    onPressed: () => _markAttendance(activeSem.id!, slot.subId, slot.slotId, 'A', ac),
                                    child: const Text('Absent'),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Quick Mark Button ────────────────────────────────────────────────────────

class _QuickMarkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickMarkButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

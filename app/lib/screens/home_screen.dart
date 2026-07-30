import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/semester_controller.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/subject_controller.dart';
import '../widgets/custom_card.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/dashed_circle_painter.dart';
import '../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int? _loadedSemId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickDate(BuildContext context, int semId, AttendanceController ac) async {
    final format = DateFormat('yyyy-MM-dd');
    final activeSem = Provider.of<SemesterController>(context, listen: false).activeSemester;
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);
    DateTime initialDate = ac.selectedDate;

    if (activeSem != null) {
      firstDate = format.parse(activeSem.startDate);
      lastDate = format.parse(activeSem.endDate);
      if (initialDate.isBefore(firstDate)) initialDate = firstDate;
      if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    }

    final unmarkedDates = ac.unmarkedDates;

    final date = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime focusedDay = initialDate;
        DateTime? selectedDay = initialDate;
        return Dialog(
          backgroundColor: Theme.of(context).extension<AppColorScheme>()!.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.025),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      firstDay: firstDate,
                      lastDay: lastDate,
                      focusedDay: focusedDay,
                      currentDay: DateTime.now(),
                      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(color: Theme.of(context).extension<AppColorScheme>()!.primary.withOpacity(0.3), shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(color: Theme.of(context).extension<AppColorScheme>()!.primary, shape: BoxShape.circle),
                        disabledTextStyle: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textMuted.withOpacity(0.3)),
                        outsideTextStyle: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textMuted.withOpacity(0.3)),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final dateStr = format.format(day);
                          if (unmarkedDates.contains(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              child: CustomPaint(
                                painter: DashedCirclePainter(color: Theme.of(context).extension<AppColorScheme>()!.unmarked),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textPrimary),
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final dateStr = format.format(day);
                          if (unmarkedDates.contains(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              child: CustomPaint(
                                painter: DashedCirclePainter(color: Theme.of(context).extension<AppColorScheme>()!.unmarked),
                                child: Container(
                                  decoration: BoxDecoration(color: Theme.of(context).extension<AppColorScheme>()!.primary.withOpacity(0.3), shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textPrimary),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          final dateStr = format.format(day);
                          if (unmarkedDates.contains(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              child: CustomPaint(
                                painter: DashedCirclePainter(color: Theme.of(context).extension<AppColorScheme>()!.unmarked),
                                child: Container(
                                  decoration: BoxDecoration(color: Theme.of(context).extension<AppColorScheme>()!.primary, shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        }
                      ),
                      onDaySelected: (newSelectedDay, newFocusedDay) {
                        setState(() {
                          selectedDay = newSelectedDay;
                          focusedDay = newFocusedDay;
                        });
                        Navigator.pop(context, newSelectedDay);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    )
                  ],
                );
              }
            ),
          ),
        );
      }
    );
    if (date != null) {
      ac.setSelectedDate(date, semId);
    }
  }

  void _markAttendance(int semId, int subId, int? slotId, int isCancelled, String studentStatus, AttendanceController ac) async {
    final error = await ac.markAttendance(semId, subId, slotId, isCancelled, studentStatus);
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
    final semesterController = Provider.of<SemesterController>(context);
    final activeSem = semesterController.activeSemester;
    final isLoading = semesterController.isLoading;
    final ac = Provider.of<AttendanceController>(context);
    final sc = Provider.of<SubjectController>(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 3,
          itemBuilder: (context, index) => const _SkeletonCard(),
        ),
      );
    }

    if (activeSem != null && activeSem.id != _loadedSemId) {
      _loadedSemId = activeSem.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ac.setSelectedDate(ac.selectedDate, activeSem.id!);
          sc.loadSubjectsForSemester(activeSem.id!);
          ac.backfillUnmarked(activeSem).then((_) {
            if (mounted) {
              ac.loadScheduleForDate(activeSem.id!);
              ac.loadUnmarkedDates(activeSem.id!);
            }
          });
        }
      });
    }

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
              onPressed: () {
                final format = DateFormat('yyyy-MM-dd');
                final semStart = format.parse(activeSem.startDate);
                final newDate = ac.selectedDate.subtract(const Duration(days: 1));
                if (newDate.isBefore(semStart)) return;
                ac.setSelectedDate(newDate, activeSem.id!);
              },
            ),
            Text(displayDate),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final format = DateFormat('yyyy-MM-dd');
                final semEnd = format.parse(activeSem.endDate);
                final newDate = ac.selectedDate.add(const Duration(days: 1));
                if (newDate.isAfter(semEnd)) return;
                ac.setSelectedDate(newDate, activeSem.id!);
              },
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
                          color: Theme.of(context).extension<AppColorScheme>()!.present,
                          onTap: () => _markAll(activeSem.id!, 'P', ac),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickMarkButton(
                          label: 'All Absent',
                          icon: Icons.cancel_outlined,
                          color: Theme.of(context).extension<AppColorScheme>()!.absent,
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
                      final isCancelled = existingAttendance?.isCancelled == 1;

                      return Dismissible(
                        key: ValueKey('${slot.slotId}_${ac.selectedDate.toIso8601String()}'),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) async {
                          final newStatus = isCancelled ? 0 : 1;
                          final currStudentStatus = existingAttendance?.studentStatus ?? 'U';
                          _markAttendance(activeSem.id!, slot.subId, slot.slotId, newStatus, currStudentStatus, ac);
                          return false; // Toggle, don't dismiss
                        },
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: Colors.red,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Icon(isCancelled ? Icons.restore : Icons.cancel, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Icon(isCancelled ? Icons.restore : Icons.cancel, color: Colors.white),
                        ),
                        child: CustomCard(
                          borderColor: isCancelled ? Colors.red : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(subName, style: Theme.of(context).textTheme.titleLarge),
                                  if (isCancelled)
                                    const Text(
                                      'CANCELLED',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    )
                                  else if (slot.classRoom.isNotEmpty)
                                    Chip(label: Text(slot.classRoom, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                             if (displayTime.isNotEmpty)
                              Text(displayTime, style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textSecondary)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isPresent
                                            ? Theme.of(context).extension<AppColorScheme>()!.present
                                            : Theme.of(context).extension<AppColorScheme>()!.surface,
                                        foregroundColor: isPresent ? Colors.white : Theme.of(context).extension<AppColorScheme>()!.textSecondary,
                                        side: BorderSide(
                                            color: isPresent
                                                ? Theme.of(context).extension<AppColorScheme>()!.present
                                                : Theme.of(context).extension<AppColorScheme>()!.textMuted.withOpacity(0.2)),
                                      ),
                                      onPressed: () => _markAttendance(activeSem.id!, slot.subId, slot.slotId, 0, isPresent ? 'U' : 'P', ac),
                                      child: const Text('Present'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isAbsent
                                            ? Theme.of(context).extension<AppColorScheme>()!.absent
                                            : Theme.of(context).extension<AppColorScheme>()!.surface,
                                        foregroundColor: isAbsent ? Colors.white : Theme.of(context).extension<AppColorScheme>()!.textSecondary,
                                        side: BorderSide(
                                            color: isAbsent
                                                ? Theme.of(context).extension<AppColorScheme>()!.absent
                                                : Theme.of(context).extension<AppColorScheme>()!.textMuted.withOpacity(0.2)),
                                      ),
                                      onPressed: () => _markAttendance(activeSem.id!, slot.subId, slot.slotId, 0, isAbsent ? 'U' : 'A', ac),
                                      child: const Text('Absent'),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
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

// ─── Skeleton Card ────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<AppColorScheme>()!.textMuted.withOpacity(0.1);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 120, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                Container(width: 50, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 80, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container(height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)))),
              ],
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/semester_controller.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/holiday_controller.dart';
import '../widgets/custom_card.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/dashed_circle_painter.dart';
import '../widgets/add_slot_modal.dart';
import '../widgets/home_slot_card.dart';
import '../config/theme.dart';
import '../models/timetable_slot.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    final holidayController = Provider.of<HolidayController>(context, listen: false);
    final holidayDates = {for (var h in holidayController.holidays) h.date: h};
    final appColors = Theme.of(context).extension<AppColorScheme>()!;

    final date = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime focusedDay = initialDate;
        DateTime? selectedDay = initialDate;
        return Dialog(
          backgroundColor: appColors.surface,
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
                        todayDecoration: BoxDecoration(color: appColors.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(color: appColors.primary, shape: BoxShape.circle),
                        disabledTextStyle: TextStyle(color: appColors.textMuted.withValues(alpha: 0.3)),
                        outsideTextStyle: TextStyle(color: appColors.textMuted.withValues(alpha: 0.3)),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final dateStr = format.format(day);
                          if (holidayDates.containsKey(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: appColors.holiday,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(color: appColors.holidayText),
                              ),
                            );
                          }
                          if (unmarkedDates.contains(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              child: CustomPaint(
                                painter: DashedCirclePainter(color: appColors.unmarked),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(color: appColors.textPrimary),
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final dateStr = format.format(day);
                          if (holidayDates.containsKey(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: appColors.holiday,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(color: appColors.holidayText),
                              ),
                            );
                          }
                          if (unmarkedDates.contains(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              child: CustomPaint(
                                painter: DashedCirclePainter(color: appColors.unmarked),
                                child: Container(
                                  decoration: BoxDecoration(color: appColors.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(color: appColors.textPrimary),
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
                          if (holidayDates.containsKey(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: appColors.holiday,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(color: appColors.holidayText),
                              ),
                            );
                          }
                          if (unmarkedDates.contains(dateStr)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              child: CustomPaint(
                                painter: DashedCirclePainter(color: appColors.unmarked),
                                child: Container(
                                  decoration: BoxDecoration(color: appColors.primary, shape: BoxShape.circle),
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
                        },
                      ),
                      onDaySelected: (newSelectedDay, newFocusedDay) {
                        HapticFeedback.selectionClick();
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

  void _markAttendance(int semId, TimetableSlot slot, int isCancelled, String studentStatus, AttendanceController ac) async {
    // Unmarking (toggle off) → light; Marking present/absent → medium
    if (studentStatus == 'U') {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    final error = await ac.markAttendance(semId, slot, isCancelled, studentStatus);
    if (error != null && mounted) {
      showErrorSnackBar(context, error);
    }
  }

  void _markAll(int semId, String studentStatus, AttendanceController ac) async {
    HapticFeedback.mediumImpact();
    final error = await ac.markAllAttendance(semId, ac.todaysSchedule, studentStatus);
    if (error != null && mounted) {
      showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
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
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final format = DateFormat('yyyy-MM-dd');
          DateTime targetDate = ac.selectedDate;

          try {
            final start = format.parse(activeSem.startDate);
            final end = format.parse(activeSem.endDate);
            if ((today.isAfter(start) || today.isAtSameMomentAs(start)) && 
                (today.isBefore(end) || today.isAtSameMomentAs(end))) {
              targetDate = today;
            } else {
              targetDate = start;
            }
          } catch (_) {}

          ac.setSelectedDate(targetDate, activeSem.id!);
          sc.loadSubjectsForSemester(activeSem.id!);
          Provider.of<HolidayController>(context, listen: false).loadHolidaysForSemester(activeSem.id!);
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
        appBar: AppBar(
          title: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              hint: const Text('Select Semester'),
              value: null,
              items: semesterController.semesters.map((s) => DropdownMenuItem(
                value: s.id, 
                child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              )).toList(),
              onChanged: (id) {
                if (id != null) {
                  final selected = semesterController.semesters.firstWhere((s) => s.id == id);
                  semesterController.setActiveSemester(selected);
                }
              },
            ),
          ),
        ),
        body: const Center(child: Text('No active semester. Please select a semester. \nOR create one from the Semesters tab.')),
      );
    }

    final format12 = DateFormat.jm();
    final format24 = DateFormat('HH:mm');
    final displayDate = DateFormat('EEE, MMM d').format(ac.selectedDate);

    final subjectMap = { for (var s in sc.subjects) s.id! : s };
    final attendanceMap = { for (var a in ac.todaysAttendance) a.slotId : a };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFutureDate = ac.selectedDate.isAfter(today);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: activeSem.id,
                isDense: true,
                items: semesterController.semesters.map((s) => DropdownMenuItem(
                  value: s.id, 
                  child: Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (id) {
                  if (id != null) {
                    final selected = semesterController.semesters.firstWhere((s) => s.id == id);
                    semesterController.setActiveSemester(selected);
                  }
                },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final format = DateFormat('yyyy-MM-dd');
                    final semStart = format.parse(activeSem.startDate);
                    final newDate = ac.selectedDate.subtract(const Duration(days: 1));
                    if (newDate.isBefore(semStart)) return;
                    HapticFeedback.selectionClick();
                    ac.setSelectedDate(newDate, activeSem.id!);
                  },
                ),
                Text(displayDate, style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final format = DateFormat('yyyy-MM-dd');
                    final semEnd = format.parse(activeSem.endDate);
                    final newDate = ac.selectedDate.add(const Duration(days: 1));
                    if (newDate.isAfter(semEnd)) return;
                    HapticFeedback.selectionClick();
                    ac.setSelectedDate(newDate, activeSem.id!);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context, activeSem.id!, ac),
                ),
                if (ac.unmarkedDates.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: CustomPaint(
                          painter: DashedCirclePainter(
                            color: appColors.unmarked,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: ac.isHoliday
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.beach_access_rounded, size: 80, color: appColors.primary.withValues(alpha: 0.8)),
                  const SizedBox(height: 16),
                  Text('Holiday!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: appColors.textPrimary)),
                  if (ac.currentHoliday?.name.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(ac.currentHoliday!.name, style: TextStyle(fontSize: 16, color: appColors.textMuted)),
                    ),
                ],
              ),
            )
          : ac.todaysSchedule.isEmpty
              ? const Center(child: Text('No classes scheduled for today.'))
              : Column(
              children: [
                // ── All Present / All Absent quick bar ──────────────────────
                if (!isFutureDate)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                    children: [
                      Expanded(
                        child: _QuickMarkButton(
                          label: 'All Present',
                          icon: Icons.check_circle_outline,
                          color: appColors.present,
                          onTap: () => _markAll(activeSem.id!, 'P', ac),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickMarkButton(
                          label: 'All Absent',
                          icon: Icons.cancel_outlined,
                          color: appColors.absent,
                          onTap: () => _markAll(activeSem.id!, 'A', ac),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Slot list ───────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 84),
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

                      return HomeSlotCard(
                        slot: slot,
                        subName: subName,
                        displayTime: displayTime,
                        existingAttendance: existingAttendance,
                        selectedDateIso: ac.selectedDate.toIso8601String(),
                        isFutureDate: isFutureDate,
                        onRemoveExtra: () async {
                          final error = await ac.removeExtraLec(activeSem.id!, slot.extraLecId!);
                          if (!context.mounted) return;
                          if (error != null) {
                            showErrorSnackBar(context, error);
                          }
                        },
                        onMarkAttendance: (int newStatus, String studentStatus) {
                          _markAttendance(activeSem.id!, slot, newStatus, studentStatus, ac);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: 
        ac.isHoliday || isFutureDate ? null : 
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (sc.subjects.isEmpty) {
                showErrorSnackBar(context, 'Please add subjects first!');
                return;
              }
              HapticFeedback.mediumImpact();
              showAddSlotModal(
                context: context,
                semId: activeSem.id!,
                dayOfWeek: 0,
                subjects: sc.subjects,
                existingSlots: ac.todaysSchedule,
                specificDate: DateFormat('yyyy-MM-dd').format(ac.selectedDate),
                onSave: (slot) => ac.addExtraLec(activeSem.id!, slot),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Extra Lec'),
            backgroundColor: appColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
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
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<AppColorScheme>()!.textMuted.withValues(alpha: 0.1);
    
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

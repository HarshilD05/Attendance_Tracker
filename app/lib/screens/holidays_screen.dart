import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../controllers/semester_controller.dart';
import '../controllers/holiday_controller.dart';
import '../models/holiday.dart';
import '../widgets/primary_button.dart';
import '../widgets/error_snackbar.dart';
import '../config/theme.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({Key? key}) : super(key: key);

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  DateTime _focusedDay = DateTime.now();

  /// When true, tapping a date immediately toggles its holiday status.
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activeSem =
          Provider.of<SemesterController>(context, listen: false).activeSemester;
      if (activeSem != null) {
        final error = await Provider.of<HolidayController>(context, listen: false)
            .loadHolidaysForSemester(activeSem.id!);
        if (error != null && mounted) {
          showErrorSnackBar(context, error);
        }

        final format = DateFormat('yyyy-MM-dd');
        final semStart = format.parse(activeSem.startDate);
        if (_focusedDay.isBefore(semStart)) {
          setState(() => _focusedDay = semStart);
        }
      }
    });
  }

  // ── View-mode popup (basic tap) ─────────────────────────────────────────────

  void _showDayPopup(DateTime selectedDay, Holiday? existingHoliday, int semId) {
    final format = DateFormat('yyyy-MM-dd');
    final displayFormat = DateFormat('MMM dd, yyyy (EEEE)');
    final dateStr = format.format(selectedDay);
    final displayStr = displayFormat.format(selectedDay);
    final nameCtrl = TextEditingController(text: existingHoliday?.name ?? '');

    showDialog(
      context: context,
      builder: (context) {
        if (existingHoliday != null) {
          // HOLIDAY -> Show edit field and Remove button
          return AlertDialog(
            backgroundColor:
                Theme.of(context).extension<AppColorScheme>()!.surface,
            title: Text(displayStr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: HOLIDAY',
                    style: TextStyle(
                        color: Theme.of(context)
                            .extension<AppColorScheme>()!
                            .absent,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Holiday Name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
              PrimaryButton(
                text: 'Remove Holiday',
                isDestructive: true,
                onPressed: () async {
                  HapticFeedback.heavyImpact();
                  final error = await Provider.of<HolidayController>(
                          context,
                          listen: false)
                      .removeHoliday(existingHoliday.id!, semId);
                  if (mounted) {
                    if (error != null) {
                      showErrorSnackBar(context, error);
                    } else {
                      Navigator.pop(context, 'removed');
                    }
                  }
                },
              ),
            ],
          );
        } else {
          // Regular Day → Show Add button
          final nameCtrl = TextEditingController();
          return AlertDialog(
            backgroundColor:
                Theme.of(context).extension<AppColorScheme>()!.surface,
            title: Text(displayStr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status: REGULAR DAY',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Holiday Name (Optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
              PrimaryButton(
                text: 'Add as Holiday',
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final newHol = Holiday(
                      semId: semId,
                      date: dateStr,
                      name: nameCtrl.text.isEmpty
                          ? 'Holiday'
                          : nameCtrl.text);
                  final error = await Provider.of<HolidayController>(
                          context,
                          listen: false)
                      .addHoliday(newHol);
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
      },
    ).then((result) async {
      if (existingHoliday != null && result != 'removed') {
        final newName = nameCtrl.text.trim();
        if (newName.isNotEmpty && newName != existingHoliday.name) {
          final updatedHol = Holiday(
            id: existingHoliday.id,
            semId: existingHoliday.semId,
            date: existingHoliday.date,
            name: newName,
          );
          if (mounted) {
            await Provider.of<HolidayController>(context, listen: false)
                .updateHoliday(updatedHol);
          }
        }
      }
    });
  }

  // ── Edit-mode toggle (tap = instant toggle) ─────────────────────────────────

  Future<void> _toggleHoliday(
      DateTime day, Holiday? existingHoliday, int semId) async {
    HapticFeedback.selectionClick();
    final hc = Provider.of<HolidayController>(context, listen: false);
    if (existingHoliday != null) {
      // Remove holiday
      final error = await hc.removeHoliday(existingHoliday.id!, semId);
      if (error != null && mounted) showErrorSnackBar(context, error);
    } else {
      // Add holiday (no-name quick add)
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final newHol = Holiday(semId: semId, date: dateStr, name: 'Holiday');
      final error = await hc.addHoliday(newHol);
      if (error != null && mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSem =
        Provider.of<SemesterController>(context).activeSemester;
    final holidayController = Provider.of<HolidayController>(context);
    
    if (activeSem == null) return const Scaffold();

    final format = DateFormat('yyyy-MM-dd');
    final semStart = format.parse(activeSem.startDate);
    final semEnd = format.parse(activeSem.endDate);

    final holidayDates = {for (var h in holidayController.holidays) h.date: h};
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Holidays'),
      ),
      body: Column(
        children: [
          // Edit mode banner
          if (_isEditMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: colors.primary.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tap any date to toggle Holiday On / Off',
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          TableCalendar(
            firstDay: semStart,
            lastDay: semEnd,
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            headerStyle:
                const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: colors.primary, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(
                  color: colors.absent, shape: BoxShape.circle),
              disabledTextStyle:
                  TextStyle(color: colors.textMuted.withOpacity(0.3)),
              outsideTextStyle:
                  TextStyle(color: colors.textMuted.withOpacity(0.3)),
            ),
            eventLoader: (day) {
              final dateStr = format.format(day);
              if (holidayDates.containsKey(dateStr)) {
                return ['Holiday'];
              }
              return [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _focusedDay = focusedDay);
              final dateStr = format.format(selectedDay);
              final existingHol = holidayDates[dateStr];

              if (_isEditMode) {
                // Quick toggle without popup
                _toggleHoliday(selectedDay, existingHol, activeSem.id!);
              } else {
                // Original popup behaviour
                HapticFeedback.selectionClick();
                _showDayPopup(selectedDay, existingHol, activeSem.id!);
              }
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isEditMode
                    ? FilledButton.icon(
                        key: const ValueKey('save'),
                        icon: const Icon(Icons.check),
                        label: const Text('Save Holidays'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.present,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _isEditMode = false);
                        },
                      )
                    : OutlinedButton.icon(
                        key: const ValueKey('edit'),
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('Mass Update Holidays'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isEditMode = true);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

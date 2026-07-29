import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activeSem = Provider.of<SemesterController>(context, listen: false).activeSemester;
      if (activeSem != null) {
        final error = await Provider.of<HolidayController>(context, listen: false).loadHolidaysForSemester(activeSem.id!);
        if (error != null && mounted) {
          showErrorSnackBar(context, error);
        }
        
        final format = DateFormat('yyyy-MM-dd');
        final semStart = format.parse(activeSem.startDate);
        if (_focusedDay.isBefore(semStart)) {
          _focusedDay = semStart;
        }
      }
    });
  }

  void _showDayPopup(DateTime selectedDay, Holiday? existingHoliday, int semId) {
    final format = DateFormat('yyyy-MM-dd');
    final displayFormat = DateFormat('MMM dd, yyyy (EEEE)');
    final dateStr = format.format(selectedDay);
    final displayStr = displayFormat.format(selectedDay);

    showDialog(
      context: context,
      builder: (context) {
        if (existingHoliday != null) {
          // It's a Holiday -> Show Remove button
          return AlertDialog(
            backgroundColor: Theme.of(context).extension<AppColorScheme>()!.surface,
            title: Text(displayStr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: HOLIDAY', style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.absent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Name: ${existingHoliday.name}'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              PrimaryButton(
                text: 'Remove Holiday',
                isDestructive: true,
                onPressed: () async {
                  final error = await Provider.of<HolidayController>(context, listen: false).removeHoliday(existingHoliday.id!, semId);
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
        } else {
          // Regular Day -> Show Add button
          final nameCtrl = TextEditingController();
          return AlertDialog(
            backgroundColor: Theme.of(context).extension<AppColorScheme>()!.surface,
            title: Text(displayStr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status: REGULAR DAY', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Holiday Name (Optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              PrimaryButton(
                text: 'Add as Holiday',
                onPressed: () async {
                  final newHol = Holiday(semId: semId, date: dateStr, name: nameCtrl.text.isEmpty ? 'Holiday' : nameCtrl.text);
                  final error = await Provider.of<HolidayController>(context, listen: false).addHoliday(newHol);
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
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = Provider.of<SemesterController>(context).activeSemester;
    final holidayController = Provider.of<HolidayController>(context);

    if (activeSem == null) return const Scaffold();

    final format = DateFormat('yyyy-MM-dd');
    final semStart = format.parse(activeSem.startDate);
    final semEnd = format.parse(activeSem.endDate);

    // Create a set of holiday date strings for quick lookup
    final holidayDates = { for (var h in holidayController.holidays) h.date : h };

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Holidays')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: semStart,
            lastDay: semEnd,
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Theme.of(context).extension<AppColorScheme>()!.primary, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Theme.of(context).extension<AppColorScheme>()!.absent, shape: BoxShape.circle),
            ),
            eventLoader: (day) {
              final dateStr = format.format(day);
              if (holidayDates.containsKey(dateStr)) {
                return ['Holiday']; // Marker dot
              }
              return [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _focusedDay = focusedDay);
              final dateStr = format.format(selectedDay);
              final existingHol = holidayDates[dateStr];
              _showDayPopup(selectedDay, existingHol, activeSem.id!);
            },
          ),
        ],
      ),
    );
  }
}

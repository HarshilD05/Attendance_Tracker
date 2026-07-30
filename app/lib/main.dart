import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'controllers/semester_controller.dart';
import 'controllers/subject_controller.dart';
import 'controllers/holiday_controller.dart';
import 'controllers/attendance_controller.dart';
import 'controllers/timetable_controller.dart';
import 'controllers/analytics_controller.dart';
import 'screens/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AttendanceTrackerApp());
}

class AttendanceTrackerApp extends StatelessWidget {
  const AttendanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SemesterController()..loadSemesters()),
        ChangeNotifierProvider(create: (_) => SubjectController()),
        ChangeNotifierProvider(create: (_) => HolidayController()),
        ChangeNotifierProvider(create: (_) => AttendanceController()),
        ChangeNotifierProvider(create: (_) => TimetableController()),
        ChangeNotifierProvider(create: (_) => AnalyticsController()),
      ],
      child: MaterialApp(
        title: 'AttenTracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const MainNavigation(),
      ),
    );
  }
}

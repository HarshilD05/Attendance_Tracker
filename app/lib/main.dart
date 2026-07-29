import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'controllers/semester_controller.dart';
import 'controllers/subject_controller.dart';
import 'controllers/holiday_controller.dart';
import 'controllers/attendance_controller.dart';

// We will import screens as we create them
// import 'screens/home_screen.dart';
// import 'screens/semesters_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Attendance Tracker',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: Text('Attendance Tracker initialized with Midnight Scholar theme!'),
          ),
        ),
        // initialRoute: '/',
        // routes: {
        //   '/': (context) => const HomeScreen(),
        //   '/semesters': (context) => const SemestersScreen(),
        // },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';
import '../screens/semester_screen.dart';
import '../screens/add_semester_screen.dart';
import '../screens/semester_detail_screen.dart';
import 'auth_wrapper.dart';

class BunkMateApp extends StatefulWidget {
  const BunkMateApp({super.key});

  @override
  State<BunkMateApp> createState() => _BunkMateAppState();
}

class _BunkMateAppState extends State<BunkMateApp> {
  final ThemeManager _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BunkMate',
      theme: _themeManager.currentTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/semesters': (context) => const SemesterScreen(),
        '/add-semester': (context) => const AddSemesterScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/semester-detail':
            final semesterId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => SemesterDetailScreen(semesterId: semesterId),
            );
          default:
            return null;
        }
      },
      builder: (context, child) {
        // Handle any navigation or overlay logic here if needed
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

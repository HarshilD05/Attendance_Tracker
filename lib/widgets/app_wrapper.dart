import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';
import '../screens/auth/login_screen.dart';

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
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Handle any navigation or overlay logic here if needed
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

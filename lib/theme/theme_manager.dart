import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => AppTheme.getTheme();

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await AppColors.setThemeMode(_isDarkMode);
    notifyListeners();
  }

  /// Set theme mode explicitly
  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await AppColors.setThemeMode(_isDarkMode);
      notifyListeners();
    }
  }

  /// Initialize theme manager
  Future<void> initialize() async {
    await AppColors.loadColors();
    notifyListeners();
  }
}

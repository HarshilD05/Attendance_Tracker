import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Light theme colors
  static Color primary = const Color(0xFF00D87B);
  static Color primaryLight = const Color(0xFF4EEAA5);
  static Color primaryDark = const Color(0xFF00B866);
  static Color secondary = const Color(0xFF00C471);
  static Color accent = const Color(0xFF00F085);
  
  static Color background = const Color(0xFFF8FFFE);
  static Color surface = const Color(0xFFFFFFFF);
  static Color card = const Color(0xFFFFFFFF);
  static Color cardElevated = const Color(0xFFF0FFFC);
  
  static Color textPrimary = const Color(0xFF1A2E2A);
  static Color textSecondary = const Color(0xFF4A6B5A);
  static Color textMuted = const Color(0xFF7A9B8A);
  
  static Color border = const Color(0xFFE0F2E8);
  static Color divider = const Color(0xFFF0FFF8);
  
  static Color error = const Color(0xFFEF4444);
  static Color warning = const Color(0xFFF59E0B);
  static Color success = const Color(0xFF00D87B);
  static Color info = const Color(0xFF3B82F6);

  // Current theme mode
  static bool _isDarkMode = false;
  static bool get isDarkMode => _isDarkMode;

  /// Load colors from JSON configuration
  static Future<void> loadColors() async {
    try {
      final String response = await rootBundle.loadString('assets/config/app_colors.json');
      final Map<String, dynamic> data = json.decode(response);
      
      final String themeKey = _isDarkMode ? 'dark_theme' : 'light_theme';
      final Map<String, dynamic> colors = data[themeKey];
      
      // Primary colors
      primary = _parseColor(colors['primary']);
      primaryLight = _parseColor(colors['primary_light']);
      primaryDark = _parseColor(colors['primary_dark']);
      secondary = _parseColor(colors['secondary']);
      accent = _parseColor(colors['accent']);
      
      // Background colors
      background = _parseColor(colors['background']);
      surface = _parseColor(colors['surface']);
      card = _parseColor(colors['card']);
      cardElevated = _parseColor(colors['card_elevated']);
      
      // Text colors
      textPrimary = _parseColor(colors['text_primary']);
      textSecondary = _parseColor(colors['text_secondary']);
      textMuted = _parseColor(colors['text_muted']);
      
      // Border colors
      border = _parseColor(colors['border']);
      divider = _parseColor(colors['divider']);
      
      // Status colors
      error = _parseColor(colors['error']);
      warning = _parseColor(colors['warning']);
      success = _parseColor(colors['success']);
      info = _parseColor(colors['info']);
      
      debugPrint('✅ Colors loaded successfully for ${_isDarkMode ? 'dark' : 'light'} theme');
      
    } catch (e) {
      // If loading fails, keep default colors
      debugPrint('❌ Error loading colors: $e');
      debugPrint('Using default fallback colors');
      _setDefaultColors();
    }
  }

  /// Set default fallback colors
  static void _setDefaultColors() {
    if (_isDarkMode) {
      // Dark theme fallback colors
      primary = const Color(0xFF22C55E);
      primaryLight = const Color(0xFF4ADE80);
      primaryDark = const Color(0xFF16A34A);
      secondary = const Color(0xFF10B981);
      accent = const Color(0xFF059669);
      
      background = const Color(0xFF0F172A);
      surface = const Color(0xFF1E293B);
      card = const Color(0xFF334155);
      cardElevated = const Color(0xFF475569);
      
      textPrimary = const Color(0xFFF8FAFC);
      textSecondary = const Color(0xFFCBD5E1);
      textMuted = const Color(0xFF94A3B8);
      
      border = const Color(0xFF475569);
      divider = const Color(0xFF334155);
    } else {
      // Light theme fallback colors (already set as defaults)
      primary = const Color(0xFF22C55E);
      primaryLight = const Color(0xFF4ADE80);
      primaryDark = const Color(0xFF16A34A);
      secondary = const Color(0xFF10B981);
      accent = const Color(0xFF059669);
      
      background = const Color(0xFFF8FAFC);
      surface = const Color(0xFFFFFFFF);
      card = const Color(0xFFFFFFFF);
      cardElevated = const Color(0xFFF1F5F9);
      
      textPrimary = const Color(0xFF1E293B);
      textSecondary = const Color(0xFF64748B);
      textMuted = const Color(0xFF94A3B8);
      
      border = const Color(0xFFE2E8F0);
      divider = const Color(0xFFF1F5F9);
    }
    
    // Status colors are the same for both themes
    error = const Color(0xFFEF4444);
    warning = const Color(0xFFF59E0B);
    success = const Color(0xFF10B981);
    info = const Color(0xFF3B82F6);
  }

  /// Toggle between light and dark theme
  static Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await loadColors();
  }

  /// Set theme mode explicitly
  static Future<void> setThemeMode(bool isDark) async {
    _isDarkMode = isDark;
    await loadColors();
  }

  /// Parse color from hex string
  static Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey; // Fallback color
    }
  }

  /// Get color scheme for Material Theme
  static ColorScheme getColorScheme() {
    return ColorScheme(
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: _isDarkMode ? textPrimary : Colors.white,
      secondary: secondary,
      onSecondary: _isDarkMode ? textPrimary : Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    );
  }

  /// Get gradient colors for backgrounds
  static List<Color> getBackgroundGradient() {
    return [
      primary.withValues( alpha: 0.1),
      background,
    ];
  }

  /// Get card shadow color
  static Color getCardShadow() {
    return _isDarkMode ? Colors.black.withValues( alpha: 0.3) : Colors.black.withValues( alpha: 0.1);
  }
}

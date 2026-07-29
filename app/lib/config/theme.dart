import 'package:flutter/material.dart';

// ─── App Color Scheme Extension ───────────────────────────────────────────────
//
// Defines the shape of required color slots for every theme.
// Hex values are filled in the darkTheme / lightTheme getters below.
// Access in widgets: Theme.of(context).extension<AppColorScheme>()!
//
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  // Surfaces
  final Color background;
  final Color surface;

  // Brand
  final Color primary;

  // Attendance status — used on home screen buttons & legend dots
  final Color present;
  final Color absent;

  // Analytics zone colors — filled based on attendance % vs threshold
  final Color attendanceSafe;     // >= minReq + 5%
  final Color attendanceWarning;  // within ± 5% of minReq
  final Color attendanceDanger;   // < minReq - 5%

  // Text hierarchy
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.primary,
    required this.present,
    required this.absent,
    required this.attendanceSafe,
    required this.attendanceWarning,
    required this.attendanceDanger,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? present,
    Color? absent,
    Color? attendanceSafe,
    Color? attendanceWarning,
    Color? attendanceDanger,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AppColorScheme(
      background:         background         ?? this.background,
      surface:            surface            ?? this.surface,
      primary:            primary            ?? this.primary,
      present:            present            ?? this.present,
      absent:             absent             ?? this.absent,
      attendanceSafe:     attendanceSafe     ?? this.attendanceSafe,
      attendanceWarning:  attendanceWarning  ?? this.attendanceWarning,
      attendanceDanger:   attendanceDanger   ?? this.attendanceDanger,
      textPrimary:        textPrimary        ?? this.textPrimary,
      textSecondary:      textSecondary      ?? this.textSecondary,
      textMuted:          textMuted          ?? this.textMuted,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      background:         Color.lerp(background,        other.background,        t)!,
      surface:            Color.lerp(surface,           other.surface,           t)!,
      primary:            Color.lerp(primary,           other.primary,           t)!,
      present:            Color.lerp(present,           other.present,           t)!,
      absent:             Color.lerp(absent,            other.absent,            t)!,
      attendanceSafe:     Color.lerp(attendanceSafe,    other.attendanceSafe,    t)!,
      attendanceWarning:  Color.lerp(attendanceWarning, other.attendanceWarning, t)!,
      attendanceDanger:   Color.lerp(attendanceDanger,  other.attendanceDanger,  t)!,
      textPrimary:        Color.lerp(textPrimary,       other.textPrimary,       t)!,
      textSecondary:      Color.lerp(textSecondary,     other.textSecondary,     t)!,
      textMuted:          Color.lerp(textMuted,         other.textMuted,         t)!,
    );
  }
}

// ─── App Theme ─────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get darkTheme {
    const scheme = AppColorScheme(
      // Surfaces
      background:        Color(0xFF121212),
      surface:           Color(0xFF1E1E1E),

      // Brand
      primary:           Color(0xFF7C4DFF),

      // Attendance status
      present:           Color(0xFF69F0AE), // soft mint-green
      absent:            Color(0xFFEF5350), // deep red

      // Analytics zone colors
      attendanceSafe:    Color(0xFF69F0AE), // soft mint-green
      attendanceWarning: Color(0xFFFFD740), // golden yellow
      attendanceDanger:  Color(0xFFEF5350), // deep red

      // Text
      textPrimary:       Colors.white,
      textSecondary:     Color(0x99FFFFFF), // white60
      textMuted:         Color(0x61FFFFFF), // white38
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scheme.background,
      primaryColor: scheme.primary,
      cardColor: scheme.surface,
      extensions: const [scheme],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
      ),
      colorScheme: ColorScheme.dark(
        primary: scheme.primary,
        surface: scheme.surface,
      ),
      textTheme: const TextTheme(
        bodyLarge:  TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.grey),
      ),
    );
  }

  static ThemeData get lightTheme {
    const scheme = AppColorScheme(
      // Surfaces
      background:        Color(0xFFF5F5F5), // Light gray background
      surface:           Color(0xFFFFFFFF), // White cards

      // Brand
      primary:           Color(0xFF7C4DFF), // Keep purple accent

      // Attendance status
      present:           Color(0xFF2E7D32), // Darker green for contrast on light bg
      absent:            Color(0xFFD32F2F), // Darker red

      // Analytics zone colors
      attendanceSafe:    Color(0xFF2E7D32), // Darker green
      attendanceWarning: Color(0xFFF57F17), // Darker orange/gold
      attendanceDanger:  Color(0xFFD32F2F), // Darker red

      // Text
      textPrimary:       Color(0xFF121212), // Near black
      textSecondary:     Color(0x99000000), // black60
      textMuted:         Color(0x61000000), // black38
    );

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: scheme.background,
      primaryColor: scheme.primary,
      cardColor: scheme.surface,
      extensions: const [scheme],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary, // Purple app bar in light mode looks good
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
      ),
      colorScheme: ColorScheme.light(
        primary: scheme.primary,
        surface: scheme.surface,
      ),
      textTheme: const TextTheme(
        bodyLarge:  TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
    );
  }
}

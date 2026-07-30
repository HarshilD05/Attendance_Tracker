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
  final Color unmarked;

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
    required this.unmarked,
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
    Color? unmarked,
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
      unmarked:           unmarked           ?? this.unmarked,
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
      unmarked:           Color.lerp(unmarked,          other.unmarked,          t)!,
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
      background:        Color(0xFF121212), // Deep pure dark
      surface:           Color(0xFF1C1C1E), // Slightly lighter for cards

      // Brand
      primary:           Color(0xFF5C52E5), // Original Deep indigo/purple

      // Attendance status
      present:           Color(0xFF2ECC71), // Original Vibrant green
      absent:            Color(0xFFE74C3C), // Original Soft red/coral
      unmarked:          Color(0xFF14BCFF), // Original Cyan Blue

      // Analytics zone colors
      attendanceSafe:    Color(0xFF2ECC71), // Original Green
      attendanceWarning: Color(0xFFF39C12), // Original Orange/Gold
      attendanceDanger:  Color(0xFFE74C3C), // Original Red

      // Text
      textPrimary:       Color(0xFFF9FAFB), // Off-white
      textSecondary:     Color(0xFFA1A1AA), // Slate gray
      textMuted:         Color(0xFF52525B), // Dark slate
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
        iconTheme: IconThemeData(color: scheme.textPrimary),
        titleTextStyle: TextStyle(
          color: scheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.textPrimary,
        unselectedLabelColor: scheme.textMuted,
        indicatorColor: scheme.primary,
      ),
      colorScheme: ColorScheme.dark(
        primary: scheme.primary,
        surface: scheme.surface,
      ),
      textTheme: TextTheme(
        bodyLarge:  TextStyle(color: scheme.textPrimary),
        bodyMedium: TextStyle(color: scheme.textSecondary),
      ),
    );
  }

  static ThemeData get lightTheme {
    const scheme = AppColorScheme(
      // Surfaces
      background:        Color(0xFFF8F9FA), // Very light gray background matching the image
      surface:           Color(0xFFFFFFFF), // White cards

      // Brand
      primary:           Color(0xFF5C52E5), // Deep indigo/purple seen in headers and active icons

      // Status & Attendance
      present:           Color(0xFF2ECC71), // Vibrant green 
      absent:            Color(0xFFE74C3C), // Soft red/coral
      unmarked:          Color(0xFF14BCFF), // Cyan Blue

      // Analytics zone colors
      attendanceSafe:    Color(0xFF2ECC71), // Green
      attendanceWarning: Color(0xFFF39C12), // Orange/Gold
      attendanceDanger:  Color(0xFFE74C3C), // Red

      // Text
      textPrimary:       Color(0xFF1E1E1E), // Near black for main headings
      textSecondary:     Color(0xFF757575), // Gray for subtitles (e.g., "Good Morning!")
      textMuted:         Color(0xFFBDBDBD), // Lighter gray for dates/timestamps
    );

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: scheme.background,
      primaryColor: scheme.primary,
      cardColor: scheme.surface,
      extensions: const [scheme],
      
      // Updated AppBar to match the image (white background, black text/icons)
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.background, 
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.textPrimary),
        titleTextStyle: TextStyle(
          color: scheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      
      // Tab bar styled for the "Exams Results" tabs seen in the image
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.textPrimary,
        unselectedLabelColor: scheme.textMuted,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.textMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      // General Color Scheme
      colorScheme: ColorScheme.light(
        primary: scheme.primary,
        surface: scheme.surface,
        error: scheme.attendanceDanger,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: scheme.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: scheme.textPrimary, fontWeight: FontWeight.bold),
        bodyLarge:  TextStyle(color: scheme.textPrimary),
        bodyMedium: TextStyle(color: scheme.textSecondary),
      ),
      
      // Card Theme for the rounded corners seen in the UI
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}

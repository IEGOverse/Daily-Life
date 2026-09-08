import 'package:flutter/material.dart';

class ActivusColors {
  ActivusColors._();

  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF131A2C);
  static const Color surfaceAlt = Color(0xFF1A2236);
  static const Color border = Color(0xFF232B40);

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFF60A5FA);

  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color category = Color(0xFF8B5CF6);
  static const Color category2 = Color(0xFF06B6D4);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);

  static const Color statusCompleted = success;
  static const Color statusInProgress = primaryBlue;
  static const Color statusSoon = warning;
  static const Color statusUpcoming = textTertiary;
}

class AppTheme {
  AppTheme._();

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: ActivusColors.primaryBlue,
    onPrimary: Colors.white,
    secondary: ActivusColors.category2,
    onSecondary: Colors.white,
    surface: Color(0xFFF5F7FA),
    onSurface: Color(0xFF1A1A2E),
    error: ActivusColors.danger,
    onError: Colors.white,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: ActivusColors.primaryBlue,
    onPrimary: Colors.white,
    secondary: ActivusColors.category2,
    onSecondary: Colors.white,
    surface: ActivusColors.surface,
    onSurface: ActivusColors.textPrimary,
    surfaceContainerHighest: ActivusColors.surfaceAlt,
    error: ActivusColors.danger,
    onError: Colors.white,
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F2F5),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF0F2F5),
      foregroundColor: Color(0xFF1A1A2E),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ActivusColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ActivusColors.background,
    cardTheme: CardThemeData(
      elevation: 0,
      color: ActivusColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ActivusColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ActivusColors.background,
      foregroundColor: ActivusColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ActivusColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ActivusColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ActivusColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ActivusColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ActivusColors.primaryBlue,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: ActivusColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dividerTheme: const DividerThemeData(
      color: ActivusColors.border,
      thickness: 1,
      space: 0,
    ),
  );
}

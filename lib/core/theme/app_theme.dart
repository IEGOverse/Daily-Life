import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4A6FA5),
    onPrimary: Colors.white,
    secondary: Color(0xFF6B8FAD),
    onSecondary: Colors.white,
    surface: Color(0xFFF5F7FA),
    onSurface: Color(0xFF1A1A2E),
    error: Color(0xFFE74C3C),
    onError: Colors.white,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6B9BD6),
    onPrimary: Colors.black,
    secondary: Color(0xFF8BB5D9),
    onSecondary: Colors.black,
    surface: Color(0xFF1A1A2E),
    onSurface: Colors.white,
    error: Color(0xFFE74C3C),
    onError: Colors.white,
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _lightScheme.primary,
    brightness: Brightness.light,
    colorScheme: _lightScheme,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _darkScheme.primary,
    brightness: Brightness.dark,
    colorScheme: _darkScheme,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[900],
    ),
  );
}

import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const primary = Color(0xFF4F46E5);       // Indigo
  static const accent = Color(0xFF14B8A6);        // Teal
  static const background = Color(0xFFF8FAFC);    // Soft white
  static const surface = Color(0xFFF1F5F9);       // Light gray
  static const textPrimary = Color(0xFF1E293B);   // Dark slate
  static const textSecondary = Color(0xFF64748B); // Medium gray

  // Code Block Colors (Dark Theme)
  static const codeBackground = Color(0xFF1E1E2E);
  static const codeText = Color(0xFFCDD6F4);
  static const codeKeyword = Color(0xFFCBA6F7);   // Purple
  static const codeString = Color(0xFFA6E3A1);    // Green
  static const codeComment = Color(0xFF6C7086);   // Gray
  static const codeNumber = Color(0xFFFAB387);    // Orange

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    fontFamily: 'Inter',
    scaffoldBackgroundColor: background,
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      elevation: 1,
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

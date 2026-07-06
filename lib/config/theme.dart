import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary300 = Color(0xFFA5B4FC);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary500 = Color(0xFF6366F1);
  static const Color primary600 = Color(0xFF4F46E5);
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary800 = Color(0xFF3730A3);
  static const Color primary900 = Color(0xFF312E81);

  // Dark colors
  static const Color dark50 = Color(0xFFF8FAFC);
  static const Color dark100 = Color(0xFFF1F5F9);
  static const Color dark200 = Color(0xFFE2E8F0);
  static const Color dark300 = Color(0xFFCBD5E1);
  static const Color dark400 = Color(0xFF94A3B8);
  static const Color dark500 = Color(0xFF64748B);
  static const Color dark600 = Color(0xFF475569);
  static const Color dark700 = Color(0xFF334155);
  static const Color dark800 = Color(0xFF1E293B);
  static const Color dark900 = Color(0xFF0F172A);
  static const Color dark950 = Color(0xFF020617);

  // Status colors
  static const Color online = Color(0xFF22C55E);
  static const Color away = Color(0xFFF59E0B);
  static const Color busy = Color(0xFFEF4444);
  static const Color offline = Color(0xFF64748B);

  // Accent colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark950,
      primaryColor: AppColors.primary500,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary500,
        secondary: AppColors.primary400,
        surface: AppColors.dark900,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dark900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dark700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dark700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.dark500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary400,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dark800,
        thickness: 1,
      ),
    );
  }
}

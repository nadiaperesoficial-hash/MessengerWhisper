import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2845E7);
  static const primaryDark = Color(0xFF1A32B8);
  static const lineGreen = Color(0xFF00C300);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F6FA);
  static const textPrimary = Color(0xFF1C1C28);
  static const textSecondary = Color(0xFF8B8D97);
  static const error = Color(0xFFE23744);
  static const border = Color(0xFFE4E6EF);
  static const navSelectedBg = Color(0xFFEDEDED);
  static const chatBackground = Color(0xFFDCE7F5);
  static const bubbleOutgoing = Color(0xFF00C300);
  static const bubbleIncoming = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      primaryColor: AppColors.lineGreen,
      primaryColorDark: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lineGreen,
        primary: AppColors.lineGreen,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lineGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lineGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lineGreen,
        ),
      ),
    );
  }
}

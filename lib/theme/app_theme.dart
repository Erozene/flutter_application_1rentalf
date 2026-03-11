import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF111111);
  static const surfaceAlt = Color(0xFF161616);
  static const border = Color(0xFF1E1E1E);
  static const borderLight = Color(0xFF2A2A2A);
  static const orange = Color(0xFFFF4E00);
  static const orangeDim = Color(0xFFCC3E00);
  static const text = Color(0xFFF0EDE6);
  static const textMuted = Color(0xFF555555);
  static const textDim = Color(0xFF888888);
  static const success = Color(0xFF4ADE80);
  static const successBg = Color(0xFF0B2211);
  static const error = Color(0xFFFF4444);
  static const errorBg = Color(0xFF2A1515);
}

class AppFonts {
  static const heading = 'BebasNeue';
  static const mono = 'DMMono';

  static TextStyle bebasNeue({
    double fontSize = 16,
    Color color = AppColors.text,
    double letterSpacing = 2,
    double? height,
  }) =>
      TextStyle(
        fontFamily: heading,
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: TextDecoration.none,
      );

  static TextStyle dmMono({
    double fontSize = 13,
    Color color = AppColors.text,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0.3,
    double? height,
    FontStyle style = FontStyle.normal,
  }) =>
      TextStyle(
        fontFamily: mono,
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: style,
        decoration: TextDecoration.none,
      );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.orange,
          surface: AppColors.surface,
          background: AppColors.bg,
          onPrimary: Colors.white,
          onSurface: AppColors.text,
        ),
        textTheme: TextTheme(
          bodyLarge: AppFonts.dmMono(color: AppColors.text),
          bodyMedium: AppFonts.dmMono(color: AppColors.text),
          bodySmall: AppFonts.dmMono(color: AppColors.textDim, fontSize: 11),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppFonts.bebasNeue(fontSize: 26, letterSpacing: 5),
          iconTheme: const IconThemeData(color: AppColors.text),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: AppFonts.dmMono(fontSize: 12, letterSpacing: 2, weight: FontWeight.w500),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            side: const BorderSide(color: AppColors.borderLight),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: AppFonts.dmMono(fontSize: 11, letterSpacing: 1.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bg,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.orange, width: 1.5),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.error),
          ),
          hintStyle: AppFonts.dmMono(color: AppColors.textMuted, fontSize: 13),
          labelStyle: AppFonts.dmMono(color: AppColors.textDim, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surface,
          contentTextStyle: AppFonts.dmMono(color: AppColors.text, fontSize: 13),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.border),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
}

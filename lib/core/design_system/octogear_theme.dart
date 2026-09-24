import 'package:flutter/material.dart';

abstract final class OctoGearColors {
  static const navy = Color(0xFF242C41);
  static const yellow = Color(0xFFF7C83C);
  static const structuralGray = Color(0xFF878380);
  static const success = Color(0xFF198754);
  static const warning = Color(0xFFF0A202);
  static const error = Color(0xFFB42318);
  static const information = Color(0xFF2E74B5);
  static const surface = Color(0xFFF8F8FA);
}

abstract final class OctoGearTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: OctoGearColors.navy,
      onPrimary: Colors.white,
      secondary: OctoGearColors.yellow,
      onSecondary: OctoGearColors.navy,
      error: OctoGearColors.error,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: OctoGearColors.navy,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OctoGearColors.surface,
      fontFamily: 'Noto Sans Arabic',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: OctoGearColors.navy,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: OctoGearColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: OctoGearColors.navy,
          side: const BorderSide(color: OctoGearColors.navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

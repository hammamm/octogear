import 'package:flutter/material.dart';

/// Color, spacing, and shape tokens shared by every OctoGear screen.
///
/// Keep product colors here rather than inventing one-off values in features.
abstract final class OctoGearColors {
  static const navy = Color(0xFF242C41);
  static const navySoft = Color(0xFF36415C);
  static const yellow = Color(0xFFF7C83C);
  static const yellowSoft = Color(0xFFFFF7DF);
  static const structuralGray = Color(0xFF6E7280);
  static const border = Color(0xFFDDE1EA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F8FB);
  static const canvas = Color(0xFFF2F3F7);
  static const success = Color(0xFF198754);
  static const warning = Color(0xFFF0A202);
  static const error = Color(0xFFB42318);
  static const information = Color(0xFF2E74B5);
}

abstract final class OctoGearSpacing {
  static const xSmall = 8.0;
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const xLarge = 32.0;
  static const xxLarge = 40.0;
}

abstract final class OctoGearRadii {
  static const small = 14.0;
  static const medium = 20.0;
  static const large = 28.0;
  static const pill = 999.0;
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
      surface: OctoGearColors.surface,
      onSurface: OctoGearColors.navy,
    );

    const inputRadius = BorderRadius.all(Radius.circular(OctoGearRadii.small));

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OctoGearColors.canvas,
      fontFamily: 'Noto Sans Arabic',
      fontFamilyFallback: const [
        'Noto Sans Arabic',
        'Noto Kufi Arabic',
        'Arial',
      ],
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: OctoGearColors.navy,
          fontSize: 31,
          fontWeight: FontWeight.w800,
          height: 1.22,
        ),
        headlineSmall: TextStyle(
          color: OctoGearColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
        titleLarge: TextStyle(
          color: OctoGearColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          color: OctoGearColors.navy,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
        bodyLarge: TextStyle(
          color: OctoGearColors.navy,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.65,
        ),
        bodyMedium: TextStyle(
          color: OctoGearColors.structuralGray,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.55,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: OctoGearColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: OctoGearColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OctoGearRadii.large),
          side: const BorderSide(color: OctoGearColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: OctoGearColors.surface,
        contentPadding: EdgeInsetsDirectional.fromSTEB(18, 19, 18, 19),
        labelStyle: TextStyle(
          color: OctoGearColors.structuralGray,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: OctoGearColors.navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: Color(0xFF9AA0AE), fontSize: 15),
        prefixStyle: TextStyle(
          color: OctoGearColors.navy,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: OctoGearColors.structuralGray,
        errorStyle: TextStyle(
          color: OctoGearColors.error,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: OctoGearColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: OctoGearColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: OctoGearColors.yellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: OctoGearColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: OctoGearColors.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: OctoGearColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB7BBC5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: OctoGearSpacing.large,
            vertical: OctoGearSpacing.medium,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(OctoGearRadii.small),
            ),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: OctoGearColors.navy,
          side: const BorderSide(color: OctoGearColors.border),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: OctoGearSpacing.medium,
            vertical: OctoGearSpacing.small,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(OctoGearRadii.small),
            ),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: OctoGearColors.navy,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: OctoGearSpacing.small,
            vertical: OctoGearSpacing.xSmall,
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: OctoGearColors.navy,
          shape: const CircleBorder(
            side: BorderSide(color: OctoGearColors.border),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: OctoGearColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: OctoGearColors.yellow,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OctoGearColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OctoGearRadii.small),
        ),
      ),
    );
  }
}

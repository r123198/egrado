import 'package:flutter/material.dart';

/// Colour tokens. Every text/background pair meets WCAG AAA (7:1) except
/// [line], which is decorative only.
abstract final class AppColors {
  static const paper = Color(0xFFF6F4EE);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF15171C);
  static const inkMuted = Color(0xFF474C55);
  static const line = Color(0xFFD9D5CB);

  static const primary = Color(0xFF1B4F8A);
  static const primarySoft = Color(0xFFE3ECF7);

  static const correct = Color(0xFF1D6B3B);
  static const correctSoft = Color(0xFFE2F1E6);
  static const wrong = Color(0xFFA3262A);
  static const wrongSoft = Color(0xFFFBE5E4);
  static const check = Color(0xFF6E4600);
  static const checkSoft = Color(0xFFFFEDC2);
}

/// Spacing scale, in logical pixels.
abstract final class Gap {
  static const xs = 6.0;
  static const s = 12.0;
  static const m = 20.0;
  static const l = 32.0;
  static const xl = 48.0;
}

/// Tallest comfortable touch target for older hands.
const double kTouchHeight = 64;

/// Atkinson Hyperlegible was designed with the Braille Institute for
/// low-vision readers: letters like I/l/1 and O/0 never look alike.
const String kFontFamily = 'AtkinsonHyperlegible';

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.inkMuted,
    onSecondary: Colors.white,
    error: AppColors.wrong,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkMuted,
    outline: AppColors.inkMuted,
    outlineVariant: AppColors.line,
  );

  // Font family is applied right here (not only via ThemeData.fontFamily)
  // because button and dialog styles below are built from these styles.
  final text =
      const TextTheme(
        displayMedium: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          height: 1.05,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleMedium: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        bodyLarge: TextStyle(fontSize: 20, height: 1.45),
        bodyMedium: TextStyle(fontSize: 18, height: 1.45),
        labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ).apply(
        fontFamily: kFontFamily,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
  const buttonSize = Size(kTouchHeight, kTouchHeight);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    textTheme: text,
    scaffoldBackgroundColor: AppColors.paper,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      toolbarHeight: 72,
      iconTheme: IconThemeData(size: 30),
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: text.labelLarge,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.inkMuted,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: text.labelLarge,
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(56, 56),
        textStyle: text.labelLarge,
        foregroundColor: AppColors.primary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(18),
      labelStyle: const TextStyle(fontSize: 20, color: AppColors.inkMuted),
      floatingLabelStyle: const TextStyle(
        fontSize: 20,
        color: AppColors.primary,
      ),
      hintStyle: const TextStyle(fontSize: 20, color: AppColors.inkMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inkMuted, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyLarge,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: kFontFamily,
        fontSize: 19,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    // Large, always-labelled tab bar that old eyes can read at a glance.
    navigationBarTheme: NavigationBarThemeData(
      height: 84,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primarySoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 30,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.inkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: kFontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.inkMuted,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}

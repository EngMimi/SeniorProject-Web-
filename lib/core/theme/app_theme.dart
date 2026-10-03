import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

// Builds the app's visual theme (colors, borders, button styles, etc).
// Only a light theme exists for now, matching the clinical color palette.
abstract final class AppTheme {
  // Builds the full Material theme used by MaterialApp.
  static ThemeData get light {
    // Start from Material's generated color scheme, then override
    // specific colors with our own brand palette.
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.navy)
        .copyWith(
          primary: AppColors.navy,
          onPrimary: AppColors.onNavy,
          primaryContainer: AppColors.softBlue,
          onPrimaryContainer: AppColors.navy,
          secondary: AppColors.accentBlue,
          onSecondary: AppColors.onNavy,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.borderStrong,
          outlineVariant: AppColors.border,
          error: AppColors.error,
          onError: AppColors.onNavy,
        );

    // Shorthand for building a text-field border in a given color/width,
    // used for all the input border states below (normal, focused, error).
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerTheme: const DividerThemeData(color: AppColors.border),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.softBlue,
        selectedIconTheme: IconThemeData(color: AppColors.navy),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: AppColors.textSecondary),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.softBlue,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 40),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: inputBorder(AppColors.borderStrong),
        enabledBorder: inputBorder(AppColors.borderStrong),
        focusedBorder: inputBorder(AppColors.navy, 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(64, 48),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.smAll,
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? const BorderSide(color: AppColors.focusRing, width: 3)
                    : null,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: const Size(64, 44),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.smAll,
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? const BorderSide(color: AppColors.navy, width: 2)
                    : const BorderSide(color: AppColors.borderStrong),
              ),
            ),
      ),
    );
  }
}

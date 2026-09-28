import 'package:flutter/material.dart';

/// Central color palette. Widgets should prefer `Theme.of(context).colorScheme`
/// and only reference these tokens directly for brand/special surfaces.
abstract final class AppColors {
  // Brand
  static const Color navy = Color(0xFF0B2545);
  static const Color onNavy = Color(0xFFFFFFFF);
  static const Color onNavyMuted = Color(0xFFB9C7DB);
  static const Color navyDivider = Color(0xFF274268);

  // Accents
  static const Color accentBlue = Color(0xFF2F6DB5);
  static const Color softBlue = Color(0xFFE6EEF8);
  static const Color focusRing = Color(0xFF7FB2F0);

  // Neutrals
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDCE3EB);
  static const Color borderStrong = Color(0xFF7D8A9C);
  static const Color textPrimary = Color(0xFF14213D);
  static const Color textSecondary = Color(0xFF52607A);

  // Status
  static const Color error = Color(0xFFB3261E);

  // Status badge tones (background / foreground pairs)
  static const Color neutralSurface = Color(0xFFEEF1F5);
  static const Color neutralForeground = Color(0xFF465366);
  static const Color infoSurface = Color(0xFFE6EEF8);
  static const Color infoForeground = Color(0xFF1D4F8C);
  static const Color warningSurface = Color(0xFFFFF1D6);
  static const Color warningForeground = Color(0xFF774A00);
  static const Color successSurface = Color(0xFFE3F3E8);
  static const Color successForeground = Color(0xFF1C6536);

  // AI result surfaces (kept visually distinct from the doctor's report)
  static const Color aiSurface = Color(0xFFF3F7FC);
  static const Color aiBorder = Color(0xFFC6D6EB);

  // Development-only UI (must never look like production UI)
  static const Color devSurface = Color(0xFFFFF6E0);
  static const Color devBorder = Color(0xFFC98A00);
  static const Color devForeground = Color(0xFF6A4000);
}

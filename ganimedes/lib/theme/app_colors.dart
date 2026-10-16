import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Canvas & Surface
  static const Color surface = Color(0xFF0B1326);
  static const Color surfaceDim = Color(0xFF0B1326);
  static const Color surfaceBright = Color(0xFF31394D);
  static const Color surfaceContainerLowest = Color(0xFF060E20);
  static const Color surfaceContainerLow = Color(0xFF131B2E);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHigh = Color(0xFF222A3D);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);

  // Dark Content
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFFC4C5D7);
  static const Color inverseSurface = Color(0xFFDAE2FD);
  static const Color inverseOnSurface = Color(0xFF283044);

  // Light Canvas & Surface
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightSurfaceDim = Color(0xFFF1F5F9);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF8FAFC);
  static const Color lightSurfaceContainer = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color lightSurfaceContainerHighest = Color(0xFFE2E8F0);

  // Light Content
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);

  // Primary
  static const Color primary = Color(0xFFB7C4FF);
  static const Color onPrimary = Color(0xFF002682);
  static const Color primaryContainer = Color(0xFF1D4ED8);
  static const Color onPrimaryContainer = Color(0xFFCAD3FF);
  static const Color inversePrimary = Color(0xFF2151DA);

  // Secondary (Electric Cyan)
  static const Color secondary = Color(0xFF4CD6FB);
  static const Color onSecondary = Color(0xFF003642);
  static const Color secondaryContainer = Color(0xFF00B2D6);
  static const Color onSecondaryContainer = Color(0xFF003F4E);

  // Light Secondary Accent (Darker cyan for contrast on light mode)
  static const Color lightSecondary = Color(0xFF0096C7);

  // Tertiary
  static const Color tertiary = Color(0xFFB9C7E4);
  static const Color onTertiary = Color(0xFF233148);
  static const Color tertiaryContainer = Color(0xFF4F5C75);
  static const Color onTertiaryContainer = Color(0xFFC7D5F3);

  // Outlines & Borders
  static const Color outline = Color(0xFF8E90A0);
  static const Color outlineVariant = Color(0xFF434655);
  static const Color borderSoft = Color(0x14FFFFFF); // dark mode border
  static const Color lightBorderSoft = Color(0xFFE2E8F0); // light mode border

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
}

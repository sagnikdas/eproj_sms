import 'package:flutter/material.dart';

/// Centralized visual + interaction tokens for Elder Shield.
///
/// Keep this small and practical: colors, spacing scale, tap targets,
/// and a few typography sizes used across the app.
class DesignTokens {
  // Brand
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF42A5F5);

  // Risk colors
  static const Color riskLow = Color(0xFF607D8B); // blue-grey
  static const Color riskMedium = Color(0xFFF57C00); // orange
  static const Color riskHigh = Color(0xFFD32F2F); // red

  // Spacing scale
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  // Radii (modern rounded corners)
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 20;
  static const double radiusPill = 999;

  // Elevation / shadows (subtle depth)
  static const double elevationCard = 0;
  static const double elevationCardHover = 1;
  static const double elevationAppBar = 0;
  static const double elevationNav = 8;

  // Accessibility / interaction
  static const double minTouchTarget = 48;

  // Typography (base sizes; actual scaling handled by app-level text scaler)
  static const double fontBody = 16;
  static const double fontBodyLarge = 18;
  static const double fontTitle = 20;

  // Animation
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
}


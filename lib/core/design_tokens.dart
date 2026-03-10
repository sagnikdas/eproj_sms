import 'package:flutter/material.dart';

/// Centralized visual + interaction tokens for Elder Shield.
///
/// Keep this small and practical: colors, spacing scale, tap targets,
/// and a few typography sizes used across the app.
class DesignTokens {
  // Brand
  static const Color primary = Color(0xFF1565C0);

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

  // Accessibility / interaction
  static const double minTouchTarget = 48;

  // Typography (base sizes; actual scaling handled by app-level text scaler)
  static const double fontBody = 16;
  static const double fontBodyLarge = 18;
  static const double fontTitle = 20;
}


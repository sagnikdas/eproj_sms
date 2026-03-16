import 'package:flutter/material.dart';

import 'package:elder_shield/core/design_tokens.dart';

/// Centralized theme configuration for Elder Shield.
///
/// Exposes light and dark [ThemeData] built on top of [DesignTokens].
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: DesignTokens.primary,
      brightness: Brightness.light,
      primary: DesignTokens.primary,
    );
    return _buildTheme(colorScheme, isDark: false);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: DesignTokens.primary,
      brightness: Brightness.dark,
      primary: DesignTokens.primaryLight,
    );
    return _buildTheme(colorScheme, isDark: true);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, {required bool isDark}) {
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );

    const bodyMedium = TextStyle(fontSize: DesignTokens.fontBody);
    const bodyLarge = TextStyle(fontSize: DesignTokens.fontBodyLarge);
    const titleMedium =
        TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.1);
    const titleLarge =
        TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.2);

    return base.copyWith(
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        elevation: DesignTokens.elevationCard,
        shadowColor: isDark ? Colors.black45 : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s24,
            vertical: DesignTokens.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s24,
            vertical: DesignTokens.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: 14,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s8,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s8,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        space: DesignTokens.s8,
        thickness: 0.8,
      ),
      textTheme: base.textTheme.copyWith(
        bodyMedium: bodyMedium,
        bodyLarge: bodyLarge,
        titleMedium: titleMedium,
        titleLarge: titleLarge,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:elder_shield/core/design_tokens.dart';

/// Shared app bar pattern used across main screens.
class ElderShieldAppBar extends AppBar {
  ElderShieldAppBar({
    super.key,
    required String titleText,
    bool showBack = false,
    VoidCallback? onBack,
    super.actions,
  }) : super(
          leading: showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                  tooltip: 'Back',
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/icon/icon.png', fit: BoxFit.contain),
                ),
          title: Text(titleText),
          backgroundColor: DesignTokens.primary,
          foregroundColor: Colors.white,
        );
}


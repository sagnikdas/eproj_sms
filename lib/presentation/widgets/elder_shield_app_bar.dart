import 'package:flutter/material.dart';
import 'package:elder_shield/core/design_tokens.dart';

/// Shared app bar pattern used across main screens.
class ElderShieldAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ElderShieldAppBar({
    super.key,
    required this.titleText,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  final String titleText;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
              tooltip: 'Back',
              style: IconButton.styleFrom(foregroundColor: Colors.white),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/icon/icon.png', fit: BoxFit.contain),
            ),
      title: Text(
        titleText,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
      ),
      backgroundColor: DesignTokens.primary,
      foregroundColor: Colors.white,
      elevation: DesignTokens.elevationAppBar,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent,
      actions: actions,
    );
  }
}


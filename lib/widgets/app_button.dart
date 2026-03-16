import 'package:flutter/material.dart';

import 'package:elder_shield/core/design_tokens.dart';

/// Primary button used across the app.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon != null
          ? Icon(icon, size: 22)
          : const SizedBox.shrink(),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(DesignTokens.minTouchTarget),
      ),
    );

    if (!expand) return button;

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}


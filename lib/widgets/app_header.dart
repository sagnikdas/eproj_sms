import 'package:flutter/material.dart';

/// Standardized screen header with title and optional subtitle.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.center = false,
  });

  final String title;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = center ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge,
          textAlign: align,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: align,
          ),
        ],
      ],
    );
  }
}


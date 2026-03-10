import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elder_shield/application/app_providers.dart';
import 'package:elder_shield/core/design_tokens.dart';
import 'package:elder_shield/presentation/home/home_screen.dart';
import 'package:elder_shield/presentation/messages/messages_screen.dart';
import 'package:elder_shield/presentation/settings/settings_screen.dart';
import 'package:elder_shield/utils/haptic.dart';

/// Bottom nav: Home, Messages, Settings.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(shellTabIndexProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          MessagesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final selected = i == currentIndex;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        selectionClick();
                        ref.read(shellTabIndexProvider.notifier).state = i;
                      },
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              t.icon,
                              size: 26,
                              color: selected
                                  ? DesignTokens.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                color: selected
                                    ? DesignTokens.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  static const _tabs = [
    _Tab(label: 'Home', icon: Icons.home_rounded),
    _Tab(label: 'Messages', icon: Icons.chat_bubble_outline_rounded),
    _Tab(label: 'Settings', icon: Icons.settings_rounded),
  ];
}

class _Tab {
  const _Tab({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

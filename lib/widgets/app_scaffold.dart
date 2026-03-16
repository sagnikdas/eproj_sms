import 'package:flutter/material.dart';

/// Standard page scaffold with `SafeArea` and consistent background behavior.
///
/// Keeps the app bar at the top and applies safe insets around the body.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      appBar: appBar,
      body: SafeArea(
        top: appBar == null,
        bottom: true,
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}


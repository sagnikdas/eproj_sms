import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elder_shield/application/app_providers.dart';
import 'package:elder_shield/data/message_repository.dart';
import 'package:elder_shield/presentation/messages/high_risk_warning_sheet.dart';

/// When [pendingHighRiskMessageProvider] is set, shows the high-risk warning sheet.
/// Also shows the sheet when the app comes to foreground (e.g. from another app)
/// with a pending message, so the warning appears over YouTube or any other app.
class HighRiskAlertListener extends ConsumerStatefulWidget {
  const HighRiskAlertListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HighRiskAlertListener> createState() =>
      _HighRiskAlertListenerState();
}

class _HighRiskAlertListenerState extends ConsumerState<HighRiskAlertListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final pending = ref.read(pendingHighRiskMessageProvider);
      if (pending != null) _showSheetFor(pending);
    }
  }

  void _showSheetFor(AnalyzedMessage message) {
    ref.read(pendingHighRiskMessageProvider.notifier).state = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showHighRiskWarningSheet(
        context,
        message: message,
        onDismiss: () {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AnalyzedMessage?>(
      pendingHighRiskMessageProvider,
      (prev, next) {
        if (next != null) _showSheetFor(next);
      },
    );
    return widget.child;
  }
}

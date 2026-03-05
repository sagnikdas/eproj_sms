import 'package:flutter/material.dart';

/// Block 10 — Short in-app summary of why we need each permission.
/// Matches [docs/permission_disclosures.md].
class PermissionsExplainedScreen extends StatelessWidget {
  const PermissionsExplainedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/icon/icon.png', fit: BoxFit.contain),
        ),
        title: const Text('Permissions explained'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Elder Shield only uses permissions for scam protection. '
                'You can deny any permission; protection will be limited but the app still works.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          _permissionCard(
            context,
            'Messages (SMS)',
            'We receive and read incoming SMS so we can analyse them for scam '
                'indicators (e.g. suspicious links, OTP phishing, bank-related wording) '
                'and show you warnings. No message content is sent off your device. '
                'You can delete all analysed history from Settings.',
          ),
          _permissionCard(
            context,
            'Phone (read state)',
            'We need to know when you\'re on a call so we can raise the risk level '
                'when an OTP arrives during a call (a common scam pattern). We do not '
                'record calls, listen to audio, or access your call log.',
          ),
          _permissionCard(
            context,
            'Phone (make calls)',
            'So you can tap "Call trusted contact" from Home or a warning. The app '
                'only starts a call when you tap the button, and only to numbers you '
                'have added as trusted contacts.',
          ),
          _permissionCard(
            context,
            'Notifications',
            'To show you alerts when we detect a suspicious or high-risk message, '
                'so you can act quickly. You can turn off notifications in system '
                'settings; you will still be able to use the app.',
          ),
        ],
      ),
    );
  }

  Widget _permissionCard(
    BuildContext context,
    String title,
    String body,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

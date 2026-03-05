import 'package:flutter/material.dart';

/// Block 10 — In-app Privacy Policy. Content matches [docs/privacy_policy_draft.md].
/// Update before publishing (e.g. contact placeholder).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/icon/icon.png', fit: BoxFit.contain),
        ),
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section(context, '1. Who we are', [
            'Elder Shield is an Android app that helps protect elderly users from '
                'SMS- and call-related scams by analysing messages on the device '
                'and warning when something looks suspicious.',
          ]),
          _section(context, '2. Data we process', [
            'All processing happens on your device. We do not send your messages, '
                'call state, or any other personal data to our servers or to any third party.',
            'Message data: When you receive an SMS, the app reads the sender, '
                'message body, and timestamp. This data is used only to run our on-device '
                'scam detection. Results are stored only on your device. You can delete '
                'all of this at any time from Settings → Delete all history.',
            'Call state: The app checks whether you are on a phone call. We do not '
                'record calls, listen to audio, or access your call log. Call state is '
                'used only to improve detection (e.g. warning when an OTP arrives during a call).',
            'Settings and trusted contacts: Stored only on your device in secure storage. '
                'Trusted contacts are used only so you can tap "Call trusted contact". '
                'We do not call or message them automatically.',
          ]),
          _section(context, '3. What we do not do', [
            'We do not send your SMS content, call state, or contact list to the internet.',
            'We do not sell, rent, or share your data with advertisers or data brokers.',
            'We do not require an account or sign-in. The app works fully offline after permissions are granted.',
            'We do not read or analyse RCS/chat messages; only standard SMS is supported.',
          ]),
          _section(context, '4. Permissions and why we need them', [
            'SMS (receive/read): To receive and read incoming SMS so we can analyse '
                'them for scam patterns and show you warnings.',
            'Phone (read phone state): To know when you\'re on a call, so we can flag '
                'higher risk when an OTP arrives during a call. We do not record or listen to calls.',
            'Phone (make calls): So you can tap "Call trusted contact". We only call '
                'numbers you have added as trusted contacts.',
            'Notifications: To show you alerts when we detect a suspicious or high-risk message.',
            'The app may open your device\'s messaging app when you choose "Block this sender"; '
                'the app does not send SMS itself.',
          ]),
          _section(context, '5. Data retention and your choices', [
            'Analyzed messages and reasons: Kept only on your device until you choose '
                'Settings → Delete all history.',
            'Settings and trusted contacts: Stored on your device until you change or '
                'remove them, or uninstall the app.',
            'We do not retain any copy of your data on our servers because we do not collect it.',
          ]),
          _section(context, '6. Children and sensitive users', [
            'The app is intended to help elderly and other vulnerable users avoid scams. '
                'We do not knowingly collect data from children in a way that would require '
                'parental consent; the app does not send data off-device. If you are a '
                'caregiver setting up the app for someone else, we recommend explaining the '
                'permissions and this policy to them.',
          ]),
          _section(context, '7. Changes to this policy', [
            'If we change this policy (for example, if we add optional cloud features in a '
                'future version), we will update this document and, where required by law '
                'or store policy, notify you or ask for consent.',
          ]),
          _section(context, '8. Contact', [
            'For privacy-related questions or requests about Elder Shield, please contact '
                '[insert your contact email or support URL here].',
          ]),
          const SizedBox(height: 24),
          Text(
            'Last updated: Block 10. Replace placeholders before release.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<String> paragraphs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

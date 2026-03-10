import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:elder_shield/application/app_providers.dart';
import 'package:elder_shield/core/design_tokens.dart';
import 'package:elder_shield/platform/overlay_alerts.dart';
import 'package:elder_shield/presentation/settings/about_screen.dart';
import 'package:elder_shield/presentation/settings/how_it_works_screen.dart';
import 'package:elder_shield/presentation/settings/permissions_explained_screen.dart';
import 'package:elder_shield/presentation/settings/privacy_policy_screen.dart';
import 'package:elder_shield/presentation/widgets/elder_shield_app_bar.dart';
import 'package:elder_shield/services/settings_service.dart';
import 'package:elder_shield/utils/haptic.dart';
import 'package:elder_shield/utils/responsive.dart';
import 'package:elder_shield/utils/snackbars.dart';

/// Settings: collapsible sections (Appearance, Text size, Legal, Sensitivity, Trusted contacts), theme, haptics.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _sensitivityMode = 'conservative';
  String _themeMode = 'system';
  bool _overlayEnabled = false;
  List<TrustedContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsServiceProvider);
    final mode = await settings.getSensitivityMode();
    final theme = await settings.getThemeMode();
    final contacts = await settings.getTrustedContacts();
    final overlayEnabled = await canDrawOverlays();
    if (mounted) {
      setState(() {
        _sensitivityMode = mode;
        _themeMode = theme;
        _overlayEnabled = overlayEnabled;
        _contacts = contacts;
      });
    }
  }

  Future<void> _setThemeMode(String mode) async {
    selectionClick();
    final settings = ref.read(settingsServiceProvider);
    await settings.setThemeMode(mode);
    ref.read(themeModeProvider.notifier).state = mode;
    setState(() => _themeMode = mode);
  }

  Future<void> _setSensitivity(String mode) async {
    selectionClick();
    final settings = ref.read(settingsServiceProvider);
    await settings.setSensitivityMode(mode);
    setState(() => _sensitivityMode = mode);
  }

  Future<void> _removeContact(int index) async {
    final updated = List<TrustedContact>.from(_contacts)..removeAt(index);
    final settings = ref.read(settingsServiceProvider);
    await settings.setTrustedContacts(updated);
    setState(() => _contacts = updated);
  }

  Future<void> _deleteAllHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text(
          'This will permanently delete all analyzed messages and reasons from this device. You cannot undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = ref.read(messageRepositoryProvider);
    try {
      await repo.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          elderSnackBar('History deleted'),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        elderSnackBar('Something went wrong. Try again.'),
      );
    }
  }

  Future<void> _rerunPermissions() async {
    await [Permission.sms, Permission.phone].request();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        elderSnackBar('Permission check done. Restart the app if you just granted access.'),
      );
    }
  }

  Future<void> _onFontScaleChanged(double value) async {
    selectionClick();
    ref.read(fontScaleProvider.notifier).state = value;
    final settings = ref.read(settingsServiceProvider);
    await settings.setFontScale(value);
  }

  Future<void> _openOverlayPermissionSettings() async {
    selectionClick();
    await openOverlayPermissionSettings();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final enabled = await canDrawOverlays();
    if (!mounted) return;
    setState(() => _overlayEnabled = enabled);
    ScaffoldMessenger.of(context).showSnackBar(
      elderSnackBar(
        enabled
            ? 'Emergency pop-up over other apps is enabled.'
            : 'Overlay permission is still off. Turn it on in system settings for emergency pop-ups.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ref.watch(fontScaleProvider);
    final padding = horizontalPadding(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ElderShieldAppBar(titleText: 'Settings'),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: DesignTokens.s16),
        children: [
          // Appearance (theme)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(Icons.palette_outlined, color: theme.colorScheme.primary, size: 24),
              title: Text('Appearance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _themeMode == 'system' ? 'System' : _themeMode == 'light' ? 'Light' : 'Dark',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onExpansionChanged: (_) => lightImpact(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ['light', 'dark', 'system'].map((mode) {
                      final label = mode == 'system' ? 'System' : mode == 'light' ? 'Light' : 'Dark';
                      return RadioListTile<String>(
                        title: Text(label),
                        value: mode,
                        groupValue: _themeMode,
                        onChanged: (v) => v != null ? _setThemeMode(v) : null,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Text size
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(Icons.text_fields_rounded, color: theme.colorScheme.primary, size: 24),
              title: Text('Text size', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${(fontScale.clamp(0.8, 1.5) * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onExpansionChanged: (_) => lightImpact(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adjust to see text larger or smaller. Changes apply immediately.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Elder Shield keeps you safe from scam messages.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('A', style: theme.textTheme.bodyMedium),
                          Expanded(
                            child: Slider(
                              value: fontScale.clamp(0.8, 1.5),
                              min: 0.8,
                              max: 1.5,
                              divisions: 7,
                              label: '${(fontScale.clamp(0.8, 1.5) * 100).round()}%',
                              onChanged: (v) => _onFontScaleChanged(v),
                            ),
                          ),
                          Text('A', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Legal & information
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(Icons.gavel_rounded, color: theme.colorScheme.primary, size: 24),
              title: Text('Legal & information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              onExpansionChanged: (_) => lightImpact(),
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy policy'),
                  subtitle: const Text('How we use your data'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                  onTap: () {
                    selectionClick();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Permissions explained'),
                  subtitle: const Text('Why we need each permission'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                  onTap: () {
                    selectionClick();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermissionsExplainedScreen()));
                  },
                ),
              ],
            ),
          ),
          // Sensitivity
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(Icons.tune_rounded, color: theme.colorScheme.primary, size: 24),
              title: Text('Sensitivity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                switch (_sensitivityMode) {
                  'conservative' => 'Fewer alerts',
                  'balanced' => 'Balanced',
                  'sensitive' => 'More alerts',
                  _ => _sensitivityMode,
                },
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onExpansionChanged: (_) => lightImpact(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    children: ['conservative', 'balanced', 'sensitive'].map((mode) {
                      final desc = switch (mode) {
                        'conservative' =>
                            'Only very obvious scams. Good if you prefer fewer alerts.',
                        'balanced' =>
                            'Good for most people. A balance of scams caught and noise.',
                        'sensitive' =>
                            'Catches more scams but may sometimes flag safe messages.',
                        _ => '',
                      };
                      final label = switch (mode) {
                        'conservative' => 'Fewer alerts',
                        'balanced' => 'Balanced',
                        'sensitive' => 'More alerts',
                        _ => mode[0].toUpperCase() + mode.substring(1),
                      };
                      return RadioListTile<String>(
                        title: Text(label),
                        subtitle: Text(desc, style: const TextStyle(fontSize: 13)),
                        value: mode,
                        groupValue: _sensitivityMode,
                        onChanged: (v) => v != null ? _setSensitivity(v) : null,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Trusted contacts
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(Icons.contacts_outlined, color: theme.colorScheme.primary, size: 24),
              title: Text('Trusted contacts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _contacts.isEmpty ? 'None' : '${_contacts.length} contact${_contacts.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onExpansionChanged: (_) => lightImpact(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You can call them with one tap from Home or when we show a scam warning. First in the list is used for the main "Call" button.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_contacts.length, (i) {
                      final c = _contacts[i];
                      return ListTile(
                        title: Text(c.name.isEmpty ? c.number : c.name),
                        subtitle: c.name.isNotEmpty ? Text(c.number) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              constraints: const BoxConstraints(
                                minWidth: DesignTokens.minTouchTarget,
                                minHeight: DesignTokens.minTouchTarget,
                              ),
                              onPressed: () {
                                selectionClick();
                                _showEditContactDialog(i);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              constraints: const BoxConstraints(
                                minWidth: DesignTokens.minTouchTarget,
                                minHeight: DesignTokens.minTouchTarget,
                              ),
                              onPressed: () async {
                                selectionClick();
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove trusted contact?'),
                                    content: const Text(
                                      'This person will no longer appear in your trusted contacts or on the Home screen.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  _removeContact(i);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          selectionClick();
                          _showEditContactDialog(i);
                        },
                      );
                    }),
                    if (_contacts.length < 3)
                      ListTile(
                        leading: const Icon(Icons.person_add),
                        title: const Text('Add contact'),
                        subtitle: const Text('Type a name and phone number'),
                        onTap: () {
                          selectionClick();
                          _showAddContactDialog();
                        },
                      ),
                    if (_contacts.length < 3)
                      ListTile(
                        leading: const Icon(Icons.contact_phone_outlined),
                        title: const Text('Choose from contacts'),
                        subtitle: const Text('Pick a number from your phone'),
                        onTap: () {
                          selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            elderSnackBar(
                              'Device contact picker is not available yet on this preview build.',
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          ), // Trusted contacts Card
          // Advanced & info
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Advanced',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      mediumImpact();
                      _deleteAllHistory();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    label: const Text('Delete all history'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      lightImpact();
                      _rerunPermissions();
                    },
                    child: const Text('Re-run permissions check'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                  leading: Icon(Icons.open_in_new_rounded, color: theme.colorScheme.primary, size: 24),
                  title: const Text('Emergency pop-up over other apps'),
                  subtitle: Text(
                    '${_overlayEnabled ? 'Enabled: high-risk warnings can appear above other apps.' : 'Off: tap to enable the Android overlay permission.'} Recommended so we can warn you even when you’re in another app.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                  onTap: _openOverlayPermissionSettings,
                ),
                ListTile(
                  leading: Icon(Icons.help_outline_rounded, color: theme.colorScheme.primary, size: 24),
                  title: const Text('How Elder Shield works'),
                  subtitle: const Text('What we check, when we alert, what to do'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                  onTap: () {
                    selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 24),
                  title: const Text('About Elder Shield'),
                  subtitle: Text(AboutScreen.appVersion),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                  onTap: () {
                    selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final ok = await _showContactDialog(
      title: 'Add trusted contact',
      consent: 'They can be called with one tap from Home or when we show a scam warning.',
      nameController: nameController,
      numberController: numberController,
      confirmLabel: 'Add',
    );
    if (ok != true || !mounted) return;
    final name = nameController.text.trim();
    final number = numberController.text.trim();
    if (number.isEmpty) return;
    final updated = [..._contacts, TrustedContact(name: name, number: number)];
    if (updated.length > 3) updated.removeRange(3, updated.length);
    final settings = ref.read(settingsServiceProvider);
    await settings.setTrustedContacts(updated);
    setState(() => _contacts = updated);
  }

  Future<void> _showEditContactDialog(int index) async {
    final c = _contacts[index];
    final nameController = TextEditingController(text: c.name);
    final numberController = TextEditingController(text: c.number);
    final ok = await _showContactDialog(
      title: 'Edit trusted contact',
      consent: null,
      nameController: nameController,
      numberController: numberController,
      confirmLabel: 'Save',
    );
    if (ok != true || !mounted) return;
    final name = nameController.text.trim();
    final number = numberController.text.trim();
    if (number.isEmpty) return;
    final updated = List<TrustedContact>.from(_contacts)
      ..[index] = TrustedContact(name: name, number: number);
    final settings = ref.read(settingsServiceProvider);
    await settings.setTrustedContacts(updated);
    setState(() => _contacts = updated);
  }

  Future<bool?> _showContactDialog({
    required String title,
    required String? consent,
    required TextEditingController nameController,
    required TextEditingController numberController,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (consent != null) ...[
              Text(
                consent,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. My son',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'e.g. +91 98765 43210',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final raw = numberController.text.trim();
              // Allow spaces, dashes, brackets etc. by validating only cleaned digits / leading plus.
              final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
              final isValid = RegExp(r'^\+?\d{6,15}$').hasMatch(cleaned);
              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  elderSnackBar('Enter a valid phone number'),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:elder_shield/application/app_providers.dart';
import 'package:elder_shield/services/settings_service.dart';
/// Settings: sensitivity mode, trusted contacts, delete history, re-run permissions, version.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _sensitivityMode = 'conservative';
  List<TrustedContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsServiceProvider);
    final mode = await settings.getSensitivityMode();
    final contacts = await settings.getTrustedContacts();
    if (mounted) {
      setState(() {
        _sensitivityMode = mode;
        _contacts = contacts;
      });
    }
  }

  Future<void> _setSensitivity(String mode) async {
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
    await repo.clearAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History deleted')),
      );
    }
  }

  Future<void> _rerunPermissions() async {
    await [Permission.sms, Permission.phone].request();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission check done. Restart the app if you just granted access.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Sensitivity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...['conservative', 'balanced', 'sensitive'].map((mode) {
            final desc = switch (mode) {
              'conservative' => 'Fewer alerts. Only very obvious scams.',
              'balanced' => 'Medium. Good for most people.',
              'sensitive' => 'More alerts. Catches more but may flag some safe messages.',
              _ => '',
            };
            return RadioListTile<String>(
              title: Text(mode[0].toUpperCase() + mode.substring(1)),
              subtitle: Text(desc, style: const TextStyle(fontSize: 13)),
              value: mode,
              // ignore: deprecated_member_use
              groupValue: _sensitivityMode,
              // ignore: deprecated_member_use
              onChanged: (v) => v != null ? _setSensitivity(v) : null,
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Trusted contacts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(_contacts.length, (i) {
            final c = _contacts[i];
            return ListTile(
              title: Text(c.name.isEmpty ? c.number : c.name),
              subtitle: c.name.isNotEmpty ? Text(c.number) : null,
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _removeContact(i),
              ),
            );
          }),
          if (_contacts.length < 3)
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add contact'),
              onTap: () => _showAddContactDialog(),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _deleteAllHistory,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete all history'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _rerunPermissions,
            child: const Text('Re-run permissions check'),
          ),
          const SizedBox(height: 32),
          Text(
            'App version: 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add trusted contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
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
}

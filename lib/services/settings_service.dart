import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A trusted contact (name + number) for one-tap call.
class TrustedContact {
  final String name;
  final String number;

  const TrustedContact({required this.name, required this.number});

  Map<String, dynamic> toJson() => {'name': name, 'number': number};

  factory TrustedContact.fromJson(Map<String, dynamic> json) =>
      TrustedContact(
        name: json['name'] as String? ?? '',
        number: json['number'] as String? ?? '',
      );
}

/// Keys used in secure storage.
class SettingsKeys {
  static const onboardingComplete = 'onboarding_complete';
  static const sensitivityMode = 'sensitivity_mode'; // e.g. 'conservative', 'balanced', 'sensitive'
  static const trustedContacts = 'trusted_contacts'; // JSON array of {name, number}
}

/// Secure settings stored in [FlutterSecureStorage].
class SettingsService {
  SettingsService(this._storage);

  final FlutterSecureStorage _storage;

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: SettingsKeys.onboardingComplete);
    return value == 'true';
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _storage.write(
      key: SettingsKeys.onboardingComplete,
      value: value.toString(),
    );
  }

  /// Get current sensitivity mode. Defaults to 'conservative' per v1 spec.
  Future<String> getSensitivityMode() async {
    return await _storage.read(key: SettingsKeys.sensitivityMode) ?? 'conservative';
  }

  Future<void> setSensitivityMode(String mode) async {
    await _storage.write(
      key: SettingsKeys.sensitivityMode,
      value: mode,
    );
  }

  /// Get trusted contacts (name + number). Max 3 for UI.
  Future<List<TrustedContact>> getTrustedContacts() async {
    final raw = await _storage.read(key: SettingsKeys.trustedContacts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(TrustedContact.fromJson)
            .toList();
      }
    } catch (_) {
      // fall through to empty list
    }
    return const [];
  }

  Future<void> setTrustedContacts(List<TrustedContact> contacts) async {
    final json = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await _storage.write(
      key: SettingsKeys.trustedContacts,
      value: json,
    );
  }

  /// Clear all secure settings (used for "reset app" flows).
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}


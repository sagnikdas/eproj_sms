import 'package:elder_shield/features/settings/data/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elder_shield/application/app_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sends WhatsApp/SMS alerts to the configured guardian contact when a
/// high-risk SMS is detected on the protected person's phone.
///
/// Privacy: NEVER includes the message body. Only shares sender ID,
/// risk level, timestamp, and the protected person's name.
class GuardianAlertService {
  GuardianAlertService(this._settingsService);

  final SettingsService _settingsService;

  /// MethodChannel to sync guardian info to native SharedPreferences so
  /// the Kotlin layer can send alerts when the app is killed.
  static const _guardianChannel = MethodChannel('elder_shield/guardian');

  // ── Rate limiting (in-memory, resets on app restart) ──────────────

  /// Minimum interval between any two alerts.
  static const _minInterval = Duration(minutes: 10);

  /// Cooldown for the same sender.
  static const _senderCooldown = Duration(hours: 1);

  /// Maximum alerts per calendar day.
  static const _maxAlertsPerDay = 10;

  DateTime? _lastAlertTime;
  final _senderLastAlertTime = <String, DateTime>{};
  final _dailyAlerts = <DateTime>[];

  /// Send an alert to the guardian. Returns silently if:
  /// - No guardian is configured
  /// - Rate limits are exceeded
  /// - The alert cannot be sent
  Future<void> alertGuardian({
    required String senderID,
    required String riskLevel,
    required DateTime timestamp,
  }) async {
    final guardian = await _settingsService.getGuardianContact();
    if (guardian == null || guardian.number.isEmpty) {
      debugPrint('[GuardianAlert] No guardian configured — skipping');
      return;
    }

    if (!_passesRateLimit(senderID)) {
      debugPrint('[GuardianAlert] Rate-limited — skipping');
      return;
    }

    final protectedName =
        await _settingsService.getProtectedPersonName() ?? 'your family member';

    final message = _composeMessage(
      protectedName: protectedName,
      senderID: senderID,
      riskLevel: riskLevel,
      timestamp: timestamp,
    );

    _recordAlert(senderID);

    final sent = await _trySendWhatsApp(guardian.number, message);
    if (!sent) {
      await _trySendSms(guardian.number, message);
    }
  }

  /// Sync guardian contact and protected person name to native SharedPreferences
  /// so the Kotlin SmsReceiver can send alerts when the app is killed.
  Future<void> syncToNative() async {
    final guardian = await _settingsService.getGuardianContact();
    final protectedName = await _settingsService.getProtectedPersonName();
    try {
      await _guardianChannel.invokeMethod('syncGuardian', {
        'guardianNumber': guardian?.number ?? '',
        'guardianName': guardian?.name ?? '',
        'protectedPersonName': protectedName ?? '',
      });
      debugPrint('[GuardianAlert] Synced guardian info to native');
    } on PlatformException catch (e) {
      debugPrint('[GuardianAlert] Failed to sync to native: $e');
    } on MissingPluginException {
      debugPrint('[GuardianAlert] Guardian channel not registered on this platform');
    }
  }

  // ── Rate limiting ─────────────────────────────────────────────────

  bool _passesRateLimit(String senderID) {
    final now = DateTime.now();

    // 1. Min interval between any alerts
    if (_lastAlertTime != null &&
        now.difference(_lastAlertTime!) < _minInterval) {
      return false;
    }

    // 2. Same sender cooldown
    final lastForSender = _senderLastAlertTime[senderID];
    if (lastForSender != null &&
        now.difference(lastForSender) < _senderCooldown) {
      return false;
    }

    // 3. Max alerts per day — prune old entries first
    final startOfDay = DateTime(now.year, now.month, now.day);
    _dailyAlerts.removeWhere((dt) => dt.isBefore(startOfDay));
    if (_dailyAlerts.length >= _maxAlertsPerDay) {
      return false;
    }

    return true;
  }

  void _recordAlert(String senderID) {
    final now = DateTime.now();
    _lastAlertTime = now;
    _senderLastAlertTime[senderID] = now;
    _dailyAlerts.add(now);
  }

  // ── Message composition ───────────────────────────────────────────

  String _composeMessage({
    required String protectedName,
    required String senderID,
    required String riskLevel,
    required DateTime timestamp,
  }) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final timeStr = '$hour12:$minute $amPm';

    return 'ElderShield Alert\n'
        'A suspicious message was detected on $protectedName\'s phone.\n'
        'Sender: $senderID\n'
        'Risk: ${riskLevel[0].toUpperCase()}${riskLevel.substring(1)}\n'
        'Time: $timeStr\n\n'
        '$protectedName is protected — the message has been flagged.';
  }

  // ── Send mechanisms ───────────────────────────────────────────────

  /// Try sending via WhatsApp deep link. Returns true if the intent was
  /// launched successfully.
  Future<bool> _trySendWhatsApp(String phoneNumber, String message) async {
    try {
      // Ensure number starts with country code, strip leading zeros
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      final whatsappUri = Uri.parse(
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        debugPrint('[GuardianAlert] WhatsApp alert sent');
        return true;
      }
    } catch (e) {
      debugPrint('[GuardianAlert] WhatsApp send failed: $e');
    }
    return false;
  }

  /// Fallback: open SMS compose screen with pre-filled message.
  Future<bool> _trySendSms(String phoneNumber, String message) async {
    try {
      final smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        debugPrint('[GuardianAlert] SMS alert sent');
        return true;
      }
    } catch (e) {
      debugPrint('[GuardianAlert] SMS send failed: $e');
    }
    return false;
  }

  /// Strip non-digit chars except leading +. If no country code, assume India (+91).
  String _cleanPhoneNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) return digits.substring(1); // wa.me expects no +
    if (digits.length == 10) return '91$digits'; // Indian number without code
    return digits;
  }
}

/// Riverpod provider for [GuardianAlertService].
final guardianAlertServiceProvider = Provider<GuardianAlertService>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return GuardianAlertService(settingsService);
});

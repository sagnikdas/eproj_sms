import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wrapper around flutter_local_notifications.
/// Block 7 will add the risk-alert logic; this file provides the
/// initialisation and a single `show()` helper.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'elder_shield_alerts';
  static const _channelName = 'Scam Alerts';
  static const _channelDesc =
      'Warnings about suspicious messages and calls';

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  /// Show a local notification immediately.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: title,
      playSound: true,
      enableVibration: true,
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}

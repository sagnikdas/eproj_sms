import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import 'package:elder_shield/data/database.dart';
import 'package:elder_shield/features/settings/data/settings_service.dart';

/// Data class for the daily heartbeat summary.
class HeartbeatData {
  final int suspiciousCount;
  final String protectedPersonName;

  const HeartbeatData({
    required this.suspiciousCount,
    required this.protectedPersonName,
  });

  Map<String, dynamic> toJson() => {
        'suspiciousCount': suspiciousCount,
        'protectedPersonName': protectedPersonName,
      };
}

/// Data class for the weekly scam summary.
class WeeklySummaryData {
  final int totalScanned;
  final int flaggedCount;
  final int highRiskCount;
  final List<String> topThreatTypes;
  final String protectedPersonName;

  const WeeklySummaryData({
    required this.totalScanned,
    required this.flaggedCount,
    required this.highRiskCount,
    required this.topThreatTypes,
    required this.protectedPersonName,
  });

  Map<String, dynamic> toJson() => {
        'totalScanned': totalScanned,
        'flaggedCount': flaggedCount,
        'highRiskCount': highRiskCount,
        'topThreatTypes': topThreatTypes,
        'protectedPersonName': protectedPersonName,
      };
}

/// Unique task names for WorkManager registration.
const _dailyHeartbeatTaskName = 'daily_heartbeat';
const _weeklySummaryTaskName = 'weekly_summary';

/// WorkManager callback dispatcher (must be a top-level function).
///
/// This runs in an isolate even when the Flutter engine is not active.
/// It syncs summary data to native SharedPreferences and triggers the
/// Kotlin HeartbeatWorker via a method channel call.
@pragma('vm:entry-point')
void heartbeatCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final service = HeartbeatService._forWorker();
      switch (taskName) {
        case _dailyHeartbeatTaskName:
          await service._syncDailyData();
          break;
        case _weeklySummaryTaskName:
          // Only run weekly summary on Sundays.
          if (DateTime.now().weekday == DateTime.sunday) {
            await service._syncWeeklyData();
          }
          break;
      }
      return true;
    } catch (_) {
      return false;
    }
  });
}

/// Service responsible for scheduling and managing daily heartbeat check-ins
/// and weekly scam summaries sent to the configured guardian contact.
///
/// Uses Flutter WorkManager for reliable background scheduling and a
/// MethodChannel (`elder_shield/heartbeat`) to sync data to the Kotlin layer,
/// which handles the actual WhatsApp/SMS delivery.
class HeartbeatService {
  HeartbeatService(this._settingsService, this._db);

  final SettingsService _settingsService;
  final AppDatabase _db;

  static const _channel = MethodChannel('elder_shield/heartbeat');

  /// Internal constructor for the WorkManager callback isolate.
  /// Uses its own database and settings service instances.
  factory HeartbeatService._forWorker() {
    // In the WorkManager isolate we don't have Riverpod, so we create
    // lightweight instances directly. The SettingsService is only used to
    // read the protected person name; the database is used for aggregation.
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return HeartbeatService(
      SettingsService(storage),
      AppDatabase.instance,
    );
  }

  /// Initialize WorkManager and register periodic heartbeat tasks.
  ///
  /// Should only be called when:
  /// - A guardian contact is configured
  /// - The premium subscription is active
  Future<void> initialize({
    required String guardianNumber,
    required String protectedPersonName,
  }) async {
    // Initialize WorkManager with our top-level callback.
    await Workmanager().initialize(
      heartbeatCallbackDispatcher,
      isInDebugMode: false,
    );

    // Sync guardian info to native SharedPreferences so the Kotlin worker
    // can read it independently of the Flutter engine.
    await _channel.invokeMethod('syncGuardianInfo', {
      'guardianNumber': guardianNumber,
      'protectedPersonName': protectedPersonName,
    });

    // Register daily heartbeat — runs every 24 hours.
    // Android WorkManager picks the best time within a ±1 hour flex window.
    await Workmanager().registerPeriodicTask(
      _dailyHeartbeatTaskName,
      _dailyHeartbeatTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntilNextTenAm(),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Register weekly summary — also runs every 24 hours, but the callback
    // checks for Sunday. This gives us weekly-on-Sunday behaviour while
    // keeping WorkManager scheduling simple.
    await Workmanager().registerPeriodicTask(
      _weeklySummaryTaskName,
      _weeklySummaryTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntilNextSundayTenAm(),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancel all heartbeat tasks (e.g. when guardian is removed or
  /// subscription lapses).
  Future<void> cancelAll() async {
    await Workmanager().cancelByUniqueName(_dailyHeartbeatTaskName);
    await Workmanager().cancelByUniqueName(_weeklySummaryTaskName);
  }

  /// Query the database for yesterday's suspicious message count.
  Future<HeartbeatData> getDailySummary() async {
    final db = await _db.database;
    final now = DateTime.now();
    final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
    final yesterdayEnd = DateTime(now.year, now.month, now.day);

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppDatabase.tableMessages} '
      'WHERE band IN (?, ?) AND timestamp >= ? AND timestamp < ?',
      [
        'medium',
        'high',
        yesterdayStart.millisecondsSinceEpoch,
        yesterdayEnd.millisecondsSinceEpoch,
      ],
    );
    final count = (result.first['c'] as int?) ?? 0;

    // Read protected person name from settings (may be null in worker).
    String name = 'Your family member';
    try {
      final stored = await _settingsService.getProtectedPersonName();
      if (stored != null && stored.isNotEmpty) name = stored;
    } catch (_) {}

    return HeartbeatData(
      suspiciousCount: count,
      protectedPersonName: name,
    );
  }

  /// Query the database for the last 7 days of message analysis stats.
  Future<WeeklySummaryData> getWeeklySummary() async {
    final db = await _db.database;
    final now = DateTime.now();
    final weekAgo = DateTime(now.year, now.month, now.day - 7);

    // Total scanned in the last 7 days.
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppDatabase.tableMessages} '
      'WHERE timestamp >= ?',
      [weekAgo.millisecondsSinceEpoch],
    );
    final totalScanned = (totalResult.first['c'] as int?) ?? 0;

    // Flagged (medium + high) in the last 7 days.
    final flaggedResult = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppDatabase.tableMessages} '
      'WHERE band IN (?, ?) AND timestamp >= ?',
      ['medium', 'high', weekAgo.millisecondsSinceEpoch],
    );
    final flaggedCount = (flaggedResult.first['c'] as int?) ?? 0;

    // High-risk only in the last 7 days.
    final highResult = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppDatabase.tableMessages} '
      'WHERE band = ? AND timestamp >= ?',
      ['high', weekAgo.millisecondsSinceEpoch],
    );
    final highRiskCount = (highResult.first['c'] as int?) ?? 0;

    // Top threat types (most frequent reasons) in the last 7 days.
    final reasonsResult = await db.rawQuery(
      'SELECT r.reason, COUNT(*) AS cnt '
      'FROM ${AppDatabase.tableReasons} r '
      'JOIN ${AppDatabase.tableMessages} m ON r.message_id = m.id '
      'WHERE m.band IN (?, ?) AND m.timestamp >= ? '
      'GROUP BY r.reason ORDER BY cnt DESC LIMIT 3',
      ['medium', 'high', weekAgo.millisecondsSinceEpoch],
    );
    final topThreatTypes =
        reasonsResult.map((r) => r['reason'] as String).toList();

    String name = 'Your family member';
    try {
      final stored = await _settingsService.getProtectedPersonName();
      if (stored != null && stored.isNotEmpty) name = stored;
    } catch (_) {}

    return WeeklySummaryData(
      totalScanned: totalScanned,
      flaggedCount: flaggedCount,
      highRiskCount: highRiskCount,
      topThreatTypes: topThreatTypes,
      protectedPersonName: name,
    );
  }

  /// Sync daily heartbeat data to native SharedPreferences and trigger
  /// the Kotlin worker to send the message.
  Future<void> _syncDailyData() async {
    final data = await getDailySummary();
    await _channel.invokeMethod('syncHeartbeatData', {
      'type': 'daily',
      'data': jsonEncode(data.toJson()),
    });
  }

  /// Sync weekly summary data to native SharedPreferences and trigger
  /// the Kotlin worker to send the message.
  Future<void> _syncWeeklyData() async {
    final data = await getWeeklySummary();
    await _channel.invokeMethod('syncHeartbeatData', {
      'type': 'weekly',
      'data': jsonEncode(data.toJson()),
    });
  }

  /// Returns the last time a heartbeat was successfully sent,
  /// as reported by the native layer.
  Future<DateTime?> getLastHeartbeatTime() async {
    try {
      final millis =
          await _channel.invokeMethod<int>('getLastHeartbeatTime');
      if (millis == null || millis == 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  /// Calculate delay from now until the next 10:00 AM.
  static Duration _delayUntilNextTenAm() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 10);
    if (now.isAfter(next)) {
      next = next.add(const Duration(days: 1));
    }
    return next.difference(now);
  }

  /// Calculate delay from now until the next Sunday at 10:00 AM.
  static Duration _delayUntilNextSundayTenAm() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 10);
    // Advance to next Sunday.
    while (next.weekday != DateTime.sunday || now.isAfter(next)) {
      next = next.add(const Duration(days: 1));
    }
    return next.difference(now);
  }
}

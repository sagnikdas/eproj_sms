import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:elder_shield/domain/detector/detector_config.dart';
import 'package:elder_shield/domain/detector/heuristic_detector.dart';
import 'package:elder_shield/services/notification_service.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _bootstrapDetectorConfig();
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: ElderShieldApp()));
}

/// Load detector configuration for scam detection.
///
/// Flow:
/// - Start from baked-in defaults (on-device, offline-safe).
/// - Try to read a cached JSON config from secure storage and, if valid,
///   apply it via [HeuristicDetector.updateConfig].
/// - If anything fails, we continue using the defaults.
Future<void> _bootstrapDetectorConfig() async {
  // Always have a safe default in place.
  HeuristicDetector.updateConfig(DetectorConfig.defaults());

  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  const key = 'detector_config_v1';

  try {
    final raw = await storage.read(key: key);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final config = DetectorConfig.fromJson(decoded);
    HeuristicDetector.updateConfig(config);
  } catch (_) {
    // On any error, we keep using the default config.
  }
}


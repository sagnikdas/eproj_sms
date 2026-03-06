import 'package:flutter/services.dart';

const _channel = MethodChannel('elder_shield/system');

/// Returns whether Android allows Elder Shield to draw above other apps.
Future<bool> canDrawOverlays() async {
  try {
    final result = await _channel.invokeMethod<bool>('canDrawOverlays');
    return result ?? false;
  } on PlatformException {
    return false;
  }
}

/// Opens the Android settings screen where the user can enable the overlay permission.
Future<void> openOverlayPermissionSettings() async {
  try {
    await _channel.invokeMethod<void>('openOverlayPermissionSettings');
  } on PlatformException {
    // Ignore and let the caller show a generic message.
  }
}

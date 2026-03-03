import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elder_shield/platform/native_event_stream.dart';
import 'package:elder_shield/domain/detector/heuristic_detector.dart';

/// Tracks whether the user is currently on a phone call.
/// Updated by [SecurityController] on every call-state event.
final isInCallProvider = StateProvider<bool>((ref) => false);

/// The [SecurityController] subscribes to native events, runs detection,
/// and will (in later blocks) persist results and trigger alerts.
class SecurityController {
  SecurityController(this._ref);

  final Ref _ref;
  final _detector = const HeuristicDetector();
  StreamSubscription<NativeEvent>? _sub;

  void start() {
    _sub = NativeEventStream.instance.events.listen(
      _onEvent,
      onError: (Object err) {
        // Log and continue — never crash on a stream error.
        // ignore: avoid_print
        print('[SecurityController] stream error: $err');
      },
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _onEvent(NativeEvent event) {
    switch (event) {
      case NativeSmsEvent(:final sms):
        _handleSms(sms);
      case NativeCallEvent(:final call):
        _handleCallState(call);
    }
  }

  void _handleSms(SmsEvent sms) {
    final inCall = _ref.read(isInCallProvider);
    final result = _detector.analyze(
      sender: sms.sender,
      body: sms.body,
      isInCall: inCall,
    );
    // ignore: avoid_print
    print('[SecurityController] SMS from ${sms.sender} → $result');
    // Persistence and alerting wired in Block 5 / Block 7.
  }

  void _handleCallState(CallStateEvent call) {
    final inCall = call.state == 'OFFHOOK' || call.state == 'RINGING';
    _ref.read(isInCallProvider.notifier).state = inCall;
    // ignore: avoid_print
    print('[SecurityController] Call state → ${call.state}');
  }
}

/// Riverpod provider so the controller can be kept alive at app root.
final securityControllerProvider = Provider<SecurityController>((ref) {
  final controller = SecurityController(ref);
  ref.onDispose(controller.stop);
  return controller;
});

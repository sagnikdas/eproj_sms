import 'dart:async';
import 'package:flutter/services.dart';

/// Matches the EventChannel name registered in MainActivity.kt.
const _channelName = 'fraud_guard/events';

/// Parsed payload for an incoming SMS event.
class SmsEvent {
  final String sender;
  final String body;
  final int timestamp; // epoch milliseconds

  const SmsEvent({
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  factory SmsEvent.fromMap(Map<Object?, Object?> map) {
    return SmsEvent(
      sender: '${map['sender'] ?? ''}',
      body: '${map['body'] ?? ''}',
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'SmsEvent(sender: $sender, ts: $timestamp, body: ${body.length > 40 ? '${body.substring(0, 40)}…' : body})';
}

/// Parsed payload for a phone-call state change event.
class CallStateEvent {
  /// Values: 'IDLE' | 'RINGING' | 'OFFHOOK'
  final String state;
  final String number;

  const CallStateEvent({required this.state, required this.number});

  factory CallStateEvent.fromMap(Map<Object?, Object?> map) {
    return CallStateEvent(
      state: '${map['state'] ?? 'IDLE'}',
      number: '${map['number'] ?? ''}',
    );
  }

  @override
  String toString() => 'CallStateEvent(state: $state, number: $number)';
}

/// Sealed union so the SecurityController can pattern-match events.
sealed class NativeEvent {}

class NativeSmsEvent extends NativeEvent {
  final SmsEvent sms;
  NativeSmsEvent(this.sms);
}

class NativeCallEvent extends NativeEvent {
  final CallStateEvent call;
  NativeCallEvent(this.call);
}

/// Exposes a broadcast stream of [NativeEvent]s from the Android native layer.
class NativeEventStream {
  NativeEventStream._();
  static final NativeEventStream instance = NativeEventStream._();

  final _channel = const EventChannel(_channelName);
  Stream<NativeEvent>? _stream;

  Stream<NativeEvent> get events {
    _stream ??= _channel
        .receiveBroadcastStream()
        .map(_parse)
        .where((e) => e != null)
        .cast<NativeEvent>();
    return _stream!;
  }

  NativeEvent? _parse(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw as Map<Object?, Object?>; // safe after is! Map check
    final type = map['type'] as String?;
    switch (type) {
      case 'sms':
        return NativeSmsEvent(SmsEvent.fromMap(map));
      case 'call_state':
        return NativeCallEvent(CallStateEvent.fromMap(map));
      default:
        return null;
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ahu_state.dart';
import '../models/ahu_telemetry.dart';
import 'account_auth_service.dart';

/// One `/api/device/<id>/status` result, keyed like a local MQTT topic
/// (`ahu|site|room|thing`) so it lands in the same dashboard card.
class AwsCloudReading {
  final String deviceId;
  final String topicKey;
  final bool online;
  final AhuTelemetry? telemetry;
  final AhuState? state;
  final DateTime? updatedAt;

  const AwsCloudReading({
    required this.deviceId,
    required this.topicKey,
    required this.online,
    this.telemetry,
    this.state,
    this.updatedAt,
  });
}

/// Polls the web dashboard for assigned AHUs whose local MQTT went quiet.
class AwsFallbackService {
  static const Duration pollInterval = Duration(seconds: 5);

  final AccountAuthService _auth;
  Timer? _timer;
  bool _busy = false;
  Iterable<String> Function()? _deviceIds;
  void Function(AwsCloudReading reading)? _onReading;

  AwsFallbackService(this._auth);

  bool get isRunning => _timer != null;

  void start({
    required Iterable<String> Function() deviceIds,
    required void Function(AwsCloudReading reading) onReading,
  }) {
    _deviceIds = deviceIds;
    _onReading = onReading;
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
    _poll();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _deviceIds = null;
    _onReading = null;
  }

  Future<void> _poll() async {
    if (_busy) return;
    final ids = _deviceIds?.call().toList() ?? const <String>[];
    if (ids.isEmpty) return;
    _busy = true;
    try {
      for (final id in ids) {
        final data = await _auth.fetchDeviceStatus(id);
        if (data == null || _onReading == null) continue;
        final reading = _parse(id, data);
        if (reading != null) _onReading?.call(reading);
      }
    } finally {
      _busy = false;
    }
  }

  AwsCloudReading? _parse(String deviceId, Map<String, dynamic> data) {
    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

    final telemetryJson = asMap(data['telemetry']);
    final stateJson = asMap(data['state']);
    if (telemetryJson.isEmpty && stateJson.isEmpty) return null;

    String field(String key) {
      final value = telemetryJson[key] ?? stateJson[key];
      return value?.toString().trim() ?? '';
    }

    final ahu = field('ahu').isNotEmpty ? field('ahu') : deviceId;
    final site = field('site').isNotEmpty ? field('site') : 'aws';
    final room = field('room').isNotEmpty ? field('room') : deviceId;
    final thing = field('thing');
    final topicKey =
        thing.isEmpty ? '$ahu|$site|$room' : '$ahu|$site|$room|$thing';

    AhuTelemetry? telemetry;
    AhuState? state;
    try {
      if (telemetryJson.isNotEmpty) {
        telemetry = AhuTelemetry.fromJson(telemetryJson);
      }
    } catch (e) {
      debugPrint('AwsFallback: telemetry parse failed for $deviceId: $e');
    }
    try {
      final merged = {...telemetryJson, ...stateJson};
      if (merged.isNotEmpty) state = AhuState.fromJson(merged);
    } catch (e) {
      debugPrint('AwsFallback: state parse failed for $deviceId: $e');
    }

    final lastUpdate = data['last_update'];
    DateTime? updatedAt;
    if (lastUpdate is num && lastUpdate > 0) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(
        (lastUpdate * 1000).round(),
      );
    }

    return AwsCloudReading(
      deviceId: deviceId,
      topicKey: topicKey,
      online: (data['status'] ?? '').toString().toLowerCase() == 'online',
      telemetry: telemetry,
      state: state,
      updatedAt: updatedAt,
    );
  }
}

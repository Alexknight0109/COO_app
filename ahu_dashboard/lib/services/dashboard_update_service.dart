import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'app_version.dart';

enum UpdatePhase { checking, upToDate, downloading, building, ready, error }

class UpdateProgress {
  final UpdatePhase phase;
  final String message;

  /// 0-100 when known.
  final int? percent;

  /// Version label of the freshly built dashboard (phase [UpdatePhase.ready]).
  final String? newVersion;

  const UpdateProgress(
    this.phase,
    this.message, {
    this.percent,
    this.newVersion,
  });

  bool get isFinal =>
      phase == UpdatePhase.upToDate ||
      phase == UpdatePhase.ready ||
      phase == UpdatePhase.error;
}

/// Talks to the local OTA updater (`rpi_ota_updater.py`) over MQTT: checks
/// GitHub, pulls and rebuilds, reporting progress until the new build is
/// ready to restart.
class DashboardUpdateService {
  static const String _broker = 'localhost';
  static const int _port = 1883;
  static const String _username = 'almed';
  static const String _password = r'Almed1234$';
  static const String _commandTopic = 'almed/rpi/ota/command';
  static const String _statusTopic = 'almed/rpi/ota/status';

  static const Duration _firstReplyTimeout = Duration(seconds: 15);
  static const Duration _silenceTimeout = Duration(minutes: 3);

  MqttServerClient? _client;
  StreamController<UpdateProgress>? _controller;
  Timer? _silenceTimer;

  /// Emits progress until a final phase (up to date, ready, or error).
  Stream<UpdateProgress> start() {
    _controller?.close();
    final controller = StreamController<UpdateProgress>(onCancel: _close);
    _controller = controller;
    _run();
    return controller.stream;
  }

  void _emit(UpdateProgress progress) {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.add(progress);
    if (progress.isFinal) _close();
  }

  void _armSilenceTimer(Duration timeout, String message) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(timeout, () {
      _emit(UpdateProgress(UpdatePhase.error, message));
    });
  }

  Future<void> _run() async {
    _emit(const UpdateProgress(
      UpdatePhase.checking,
      'Checking for updates...',
    ));

    final clientId = 'ahu_dash_update_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(_broker, clientId, _port)
      ..logging(on: false)
      ..keepAlivePeriod = 30
      ..connectTimeoutPeriod = 5000
      ..autoReconnect = false;
    _client = client;

    try {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(_username, _password)
          .startClean();
      await client.connect().timeout(const Duration(seconds: 8));
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        throw StateError('not connected');
      }
    } catch (_) {
      _emit(const UpdateProgress(
        UpdatePhase.error,
        'Cannot reach the local update service',
      ));
      return;
    }

    var updateSent = false;
    client.updates?.listen((events) {
      for (final event in events) {
        if (event.topic != _statusTopic) continue;
        final payload = event.payload as MqttPublishMessage;
        final text =
            MqttPublishPayload.bytesToStringAsString(payload.payload.message);
        Map<String, dynamic> status;
        try {
          final decoded = jsonDecode(text);
          if (decoded is! Map<String, dynamic>) continue;
          status = decoded;
        } catch (_) {
          continue;
        }
        if (_handleStatus(status, updateSent)) updateSent = true;
      }
    });
    client.subscribe(_statusTopic, MqttQos.atLeastOnce);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _armSilenceTimer(
      _firstReplyTimeout,
      'Update service did not respond. Start ahu-ota-updater on this Radxa.',
    );
    _publish({'type': 'check_update', 'running_commit': _runningCommit});
  }

  String get _runningCommit {
    final label = AppVersion.label;
    final i = label.indexOf('· ');
    return i < 0 ? '' : label.substring(i + 2).trim();
  }

  /// Returns true when it sent the update command.
  bool _handleStatus(Map<String, dynamic> status, bool updateSent) {
    final state = (status['status'] ?? '').toString();
    final message = (status['message'] ?? '').toString();
    final percent = (status['progress'] as num?)?.round();

    _armSilenceTimer(_silenceTimeout, 'Update stopped responding');

    switch (state) {
      case 'checking':
        _emit(const UpdateProgress(UpdatePhase.checking, 'Checking for updates...'));
        return false;
      case 'up_to_date':
        _emit(UpdateProgress(
          UpdatePhase.upToDate,
          'You are on the latest version (${AppVersion.label})',
        ));
        return false;
      case 'update_available':
        if (updateSent) return false;
        _emit(UpdateProgress(
          UpdatePhase.downloading,
          message.isEmpty ? 'Update found' : message,
          percent: 5,
        ));
        _publish({
          'type': 'ota_update',
          'confirm_restart': true,
          'running_commit': _runningCommit,
        });
        return true;
      case 'starting':
      case 'pulling':
      case 'pulled':
        _emit(UpdateProgress(
          UpdatePhase.downloading,
          message.isEmpty ? 'Downloading update...' : message,
          percent: percent,
        ));
        return false;
      case 'building':
        _emit(UpdateProgress(
          UpdatePhase.building,
          message.isEmpty ? 'Building new version...' : message,
          percent: percent,
        ));
        return false;
      case 'ready_to_restart':
      case 'complete':
        _emit(UpdateProgress(
          UpdatePhase.ready,
          message.isEmpty ? 'Update installed' : message,
          percent: 100,
          newVersion: status['new_version']?.toString(),
        ));
        return false;
      case 'error':
        _emit(UpdateProgress(
          UpdatePhase.error,
          message.isEmpty ? 'Update failed' : message,
        ));
        return false;
      default:
        return false;
    }
  }

  /// Fallback restart through the updater when the in-app relaunch is
  /// unavailable.
  Future<void> requestRestart() async {
    final clientId = 'ahu_dash_restart_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(_broker, clientId, _port)
      ..logging(on: false)
      ..connectTimeoutPeriod = 5000
      ..autoReconnect = false;
    try {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(_username, _password)
          .startClean();
      await client.connect().timeout(const Duration(seconds: 8));
      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode({'type': 'restart'}));
      client.publishMessage(_commandTopic, MqttQos.atLeastOnce, builder.payload!);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } catch (_) {
    } finally {
      client.disconnect();
    }
  }

  void _publish(Map<String, dynamic> command) {
    final client = _client;
    if (client == null) return;
    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(command));
    client.publishMessage(_commandTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _close() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _client?.disconnect();
    _client = null;
    final controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) controller.close();
  }

  void dispose() => _close();
}

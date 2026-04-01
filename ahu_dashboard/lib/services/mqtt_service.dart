import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/ahu_telemetry.dart';
import '../models/ahu_state.dart';
import '../models/ahu_log.dart';
import '../models/ahu_unit.dart';

/// MQTT service for communicating with ESP32 AHU units
class MqttService {
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSubscription;
  final String broker;
  final int port;
  final String username;
  final String password;
  final bool useTLS;

  // Stream controllers for different message types
  final _telemetryController = StreamController<MapEntry<String, AhuTelemetry>>.broadcast();
  final _stateController = StreamController<MapEntry<String, AhuState>>.broadcast();
  final _logController = StreamController<MapEntry<String, AhuLog>>.broadcast();
  final _statusController = StreamController<MapEntry<String, String>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _awsStatusController = StreamController<MapEntry<String, bool>>.broadcast();

  // Public streams
  Stream<MapEntry<String, AhuTelemetry>> get telemetryStream => _telemetryController.stream;
  Stream<MapEntry<String, AhuState>> get stateStream => _stateController.stream;
  Stream<MapEntry<String, AhuLog>> get logStream => _logController.stream;
  Stream<MapEntry<String, String>> get statusStream => _statusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<MapEntry<String, bool>> get awsStatusStream => _awsStatusController.stream;

  bool _isConnected = false;
  bool _rootSubscribed = false;
  bool get isConnected => _isConnected;

  MqttService({
    required this.broker,
    this.port = 1883,
    required this.username,
    required this.password,
    this.useTLS = false,
  });

  /// Connect to MQTT broker
  Future<bool> connect() async {
    try {
      final clientId = 'ahu_dashboard_${DateTime.now().millisecondsSinceEpoch}';
      _updatesSubscription?.cancel();
      _client = MqttServerClient.withPort(broker, clientId, port)
        ..logging(on: false)
        ..keepAlivePeriod = 60
        ..connectTimeoutPeriod = 3000  // 3 second timeout - don't block UI
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onSubscribed = _onSubscribed
        ..pongCallback = _pong
        ..autoReconnect = true  // Auto-reconnect in background
        ..resubscribeOnAutoReconnect = true;

      if (kIsWeb) {
        _client!
          ..useWebSocket = true
          ..websocketProtocols = MqttClientConstants.protocolsSingleDefault;
      }

      if (useTLS) {
        _client!.secure = true;
        debugPrint('MQTT: TLS enabled for ${kIsWeb ? "web" : "native"} connection');
      }

      _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .withWillTopic('ahu_dashboard/status')
        .withWillMessage('offline')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

      await _client!.connect().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('MQTT: Connection timeout - will retry in background');
          return null;
        },
      );

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('MQTT: Connected to $broker:$port ${useTLS ? "(TLS)" : ""}');
        _isConnected = true;
        _rootSubscribed = false;
        _connectionController.add(true);

        _subscribeRootTopics();
        _updatesSubscription = _client!.updates!.listen(_onMessage);

        return true;
      } else {
        debugPrint('MQTT: Connection failed - ${_client!.connectionStatus}');
        _isConnected = false;
        _connectionController.add(false);
        return false;
      }
    } catch (e) {
      debugPrint('MQTT: Connection error - $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  /// Disconnect from MQTT broker
  void disconnect() {
    _client?.disconnect();
  }

  /// Subscribe to specific AHU topics
  void subscribeToAhu(AhuUnit ahu) {
    // Root wildcard subscription already covers all AHU topics.
    if (_client == null || !_isConnected) return;
    _subscribeRootTopics();
  }

  /// Send command to AHU
  bool sendCommand(AhuUnit ahu, Map<String, dynamic> command) {
    if (_client == null) {
      debugPrint('MQTT: Cannot send command - client is null');
      return false;
    }
    if (!_isConnected) {
      debugPrint('MQTT: Cannot send command - not connected');
      return false;
    }

    try {
      final payload = jsonEncode(command);
      final builder = MqttClientPayloadBuilder()..addString(payload);
      _client!.publishMessage(ahu.cmdTopic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('MQTT: Command sent to ${ahu.cmdTopic}: $payload');
      return true;
    } catch (e) {
      debugPrint('MQTT: Error sending command: $e');
      return false;
    }
  }

  /// Start AHU
  void startAhu(AhuUnit ahu) => sendCommand(ahu, {'start': true});

  /// Stop AHU
  void stopAhu(AhuUnit ahu) => sendCommand(ahu, {'stop': true});

  /// Toggle AHU
  void toggleAhu(AhuUnit ahu) => sendCommand(ahu, {'toggle': true});

  /// Set temperature setpoint
  void setTemperature(AhuUnit ahu, double temp) => sendCommand(ahu, {'setpoint': temp});

  /// Set humidity setpoint
  void setHumidity(AhuUnit ahu, double humidity) => sendCommand(ahu, {'humset': humidity});

  /// Set fan speed (0=OFF, 1=LOW, 2=MED, 3=HIGH)
  void setFanSpeed(AhuUnit ahu, int speed) {
    if (speed >= 0 && speed <= 3) {
      sendCommand(ahu, {'fan': speed});
    }
  }

  /// Toggle fan speed
  void toggleFanSpeed(AhuUnit ahu) => sendCommand(ahu, {'fanToggle': true});

  /// Set operation mode (true = online/cloud, false = offline/local only)
  void setMode(AhuUnit ahu, bool onlineMode) => sendCommand(ahu, {'mode': onlineMode ? 'online' : 'offline'});

  /// Set CP mode ("dual" = auto-switch every hour, "single" = use single CP)
  void setCpMode(AhuUnit ahu, String mode) => sendCommand(ahu, {'cpMode': mode});

  /// Set active CP (1 or 2) - only used in single mode
  void setCpActive(AhuUnit ahu, int cpActive) => sendCommand(ahu, {'cpActive': cpActive});

  /// Reset ESP32 (same as pressing physical reset button)
  void resetEsp32(AhuUnit ahu) => sendCommand(ahu, {'reset': true});

  /// Provision WiFi credentials
  void provisionWifi(
    AhuUnit ahu, {
    String? primarySsid,
    String? primaryPass,
    String? secondarySsid,
    String? secondaryPass,
  }) {
    if (_client == null || !_isConnected) return;

    final payload = <String, dynamic>{};

    if (primarySsid != null && primaryPass != null) {
      payload['primary'] = {'ssid': primarySsid, 'pass': primaryPass};
    }

    if (secondarySsid != null && secondaryPass != null) {
      payload['secondary'] = {'ssid': secondarySsid, 'pass': secondaryPass};
    }

    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(payload));
    _client!.publishMessage(ahu.provWifiTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Provision broker settings
  void provisionBroker(AhuUnit ahu, String host, int port) {
    if (_client == null || !_isConnected) return;

    final builder = MqttClientPayloadBuilder()
      ..addString(jsonEncode({'host': host, 'port': port}));
    _client!.publishMessage(ahu.provBrokerTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Provision motor timings
  void provisionMotorTimings(
    AhuUnit ahu, {
    int? m1Start,
    int? m1Post,
    int? m2Interval,
    int? m2Run,
    int? m2Delay,
  }) {
    if (_client == null || !_isConnected) return;

    final payload = <String, dynamic>{};
    if (m1Start != null) payload['m1_start'] = m1Start;
    if (m1Post != null) payload['m1_post'] = m1Post;
    if (m2Interval != null) payload['m2_interval'] = m2Interval;
    if (m2Run != null) payload['m2_run'] = m2Run;
    if (m2Delay != null) payload['m2_delay'] = m2Delay;

    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(payload));
    _client!.publishMessage(ahu.provMotorTimingsTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  // Callbacks
  void _onConnected() {
    debugPrint('MQTT: Connected');
    _isConnected = true;
    _subscribeRootTopics();
    _connectionController.add(true);
  }

  void _onDisconnected() {
    debugPrint('MQTT: Disconnected');
    _isConnected = false;
    _rootSubscribed = false;
    _connectionController.add(false);
  }

  void _onSubscribed(String topic) {
    debugPrint('MQTT: Subscribed to $topic');
  }

  void _pong() {
    // Keep-alive pong received
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      _processMessage(message);
    }
  }

  void _processMessage(MqttReceivedMessage<MqttMessage> message) {
    final topic = message.topic;
    final payload = message.payload as MqttPublishMessage;
    final payloadString = MqttPublishPayload.bytesToStringAsString(payload.payload.message);

    // Extract AHU info for logging
    if (!topic.startsWith('almed/ahu/')) return;
    final parts = topic.split('/');
    if (parts.length < 6) return;

    final kind = parts.last;
    const supportedKinds = {
      'telemetry',
      'state',
      'log',
      'status',
      'aws_status',
    };
    if (!supportedKinds.contains(kind)) return;

    // Parse from the tail so topics stay valid even when SITE contains '/'.
    final ahuId = parts[parts.length - 2];
    final room = parts[parts.length - 3];
    final siteParts = parts.sublist(2, parts.length - 3);
    final site = siteParts.isNotEmpty ? siteParts.join('/') : 'hospitalA';
    final topicData = '$ahuId|$site|$room';
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      if (topic.endsWith('/telemetry')) {
        final data = jsonDecode(payloadString) as Map<String, dynamic>;
        _telemetryController.add(MapEntry(topicData, AhuTelemetry.fromJson(data)));
      } else if (topic.endsWith('/state')) {
        final data = jsonDecode(payloadString) as Map<String, dynamic>;
        _stateController.add(MapEntry(topicData, AhuState.fromJson(data)));
        // Log state changes (when run state changes)
        final runState = data['run'] ?? false;
        final m1State = data['m1'] ?? false;
        final m2State = data['m2'] ?? false;
        final cpState = data['cp'] ?? false;
        final heaterState = data['heater'] ?? false;
        _addLogEntry(topicData, now, 'INFO', '[State] Run:${runState ? "ON" : "OFF"} M1:${m1State ? "ON" : "OFF"} M2:${m2State ? "ON" : "OFF"} CP:${cpState ? "ON" : "OFF"} Heat:${heaterState ? "ON" : "OFF"}');
      } else if (topic.endsWith('/log')) {
        // Handle both JSON and plain text log messages
        try {
          // Try to parse as JSON first
          final data = jsonDecode(payloadString) as Map<String, dynamic>;
          final logEntry = AhuLog.fromJson(data);
          _logController.add(MapEntry(topicData, logEntry));
          debugPrint('MQTT: Log received (JSON) from $topic: ${logEntry.msg}');
        } catch (e) {
          // If JSON parsing fails, treat as plain text message
          final logLevel = _extractLogLevel(payloadString);
          _addLogEntry(topicData, now, logLevel, payloadString.trim());
          debugPrint('MQTT: Log received (plain text) from $topic: ${payloadString.trim()}');
        }
      } else if (topic.endsWith('/status')) {
        _statusController.add(MapEntry(topicData, payloadString));
        // Log status updates
        _addLogEntry(topicData, now, 'INFO', '[Status] $payloadString');
      } else if (topic.endsWith('/aws_status')) {
        // Handle AWS IoT connection status from ESP32
        try {
          final data = jsonDecode(payloadString) as Map<String, dynamic>;
          final connected = data['connected'] as bool? ?? false;
          _awsStatusController.add(MapEntry(topicData, connected));
          debugPrint('MQTT: AWS status received from $ahuId: ${connected ? "CONNECTED" : "DISCONNECTED"}');
          
          // Log to dashboard
          final statusMsg = connected ? '☁️ Cloud connected (AWS IoT)' : '⚠️ Cloud disconnected';
          _addLogEntry(topicData, now, connected ? 'INFO' : 'WARN', statusMsg);
        } catch (e) {
          debugPrint('MQTT: Error parsing aws_status: $e');
        }
      } else {
        // Capture any other messages from AHU topics as logs
        _addLogEntry(topicData, now, 'INFO', '[MQTT] $topic: ${payloadString.length > 100 ? payloadString.substring(0, 100) + "..." : payloadString}');
      }
    } catch (e) {
      debugPrint('MQTT: Error parsing message from $topic: $e');
      // If message parsing fails but topic contains 'log', try to capture as log anyway
      if (topic.contains('/log') || topic.toLowerCase().contains('log')) {
        try {
          final parts = topic.split('/');
          if (parts.length >= 5) {
            final ahuId = parts[4];
            final site = parts.length > 2 ? parts[2] : 'hospitalA';
            final room = parts.length > 3 ? parts[3] : 'room1';
            final topicData = '$ahuId|$site|$room';
            final now = DateTime.now().millisecondsSinceEpoch;
            _logController.add(MapEntry(topicData, AhuLog(
              ts: now,
              lvl: 'INFO',
              msg: '[MQTT Error] $topic: ${payloadString.length > 200 ? payloadString.substring(0, 200) + "..." : payloadString}',
            )));
          }
        } catch (_) {
          // Ignore errors in error handler
        }
      }
    }
  }

  /// Add log entry to the log stream
  void _addLogEntry(String topicData, int timestamp, String level, String message) {
    _logController.add(MapEntry(topicData, AhuLog(
      ts: timestamp,
      lvl: level,
      msg: message,
    )));
  }

  /// Extract log level from plain text message
  String _extractLogLevel(String message) {
    final msgUpper = message.toUpperCase();
    if (msgUpper.contains('ERROR') || msgUpper.contains('❌') || msgUpper.contains('FAILED')) {
      return 'ERROR';
    } else if (msgUpper.contains('WARN') || msgUpper.contains('⚠️') || msgUpper.contains('WARNING')) {
      return 'WARN';
    } else {
      return 'INFO';
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _updatesSubscription?.cancel();
    _telemetryController.close();
    _stateController.close();
    _logController.close();
    _statusController.close();
    _connectionController.close();
    _awsStatusController.close();
  }

  void _subscribeRootTopics() {
    if (_client == null || !_isConnected || _rootSubscribed) return;
    _client!.subscribe('almed/ahu/#', MqttQos.atLeastOnce);
    _rootSubscribed = true;
  }
}

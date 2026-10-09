import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Asks the local OTA updater to check GitHub and install a newer dashboard.
class DashboardUpdateService {
  static const String _broker = 'localhost';
  static const int _port = 1883;
  static const String _username = 'almed';
  static const String _password = r'Almed1234$';
  static const String _commandTopic = 'almed/rpi/ota/command';
  static const String _statusTopic = 'almed/rpi/ota/status';

  Future<String> checkAndUpdate() async {
    final clientId = 'ahu_dash_update_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(_broker, clientId, _port)
      ..logging(on: false)
      ..keepAlivePeriod = 30
      ..connectTimeoutPeriod = 5000
      ..autoReconnect = false;

    final pending = <Map<String, dynamic>>[];
    var waiter = Completer<void>();
    StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? updates;

    void push(Map<String, dynamic> status) {
      pending.add(status);
      if (!waiter.isCompleted) waiter.complete();
    }

    Future<Map<String, dynamic>?> nextStatus(Duration timeout) async {
      if (pending.isEmpty) {
        try {
          await waiter.future.timeout(timeout);
        } on TimeoutException {
          return null;
        }
      }
      if (pending.isEmpty) return null;
      return pending.removeAt(0);
    }

    try {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(_username, _password)
          .startClean();

      await client.connect().timeout(const Duration(seconds: 8));
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        return 'Cannot reach the local update service';
      }

      updates = client.updates?.listen((events) {
        for (final event in events) {
          if (event.topic != _statusTopic) continue;
          final payload = event.payload as MqttPublishMessage;
          final text = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message,
          );
          try {
            final decoded = jsonDecode(text);
            if (decoded is Map<String, dynamic>) push(decoded);
          } catch (_) {}
        }
      });
      client.subscribe(_statusTopic, MqttQos.atLeastOnce);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      _publish(client, {'type': 'check_update'});

      var updateSent = false;
      var heard = false;
      final deadline = DateTime.now().add(const Duration(minutes: 45));
      while (DateTime.now().isBefore(deadline)) {
        final remaining = deadline.difference(DateTime.now());
        final wait = remaining < const Duration(seconds: 30)
            ? remaining
            : const Duration(seconds: 30);
        final status = await nextStatus(wait);
        if (status == null) {
          if (!heard) {
            return 'Update service did not respond. Start ahu-ota-updater on this Radxa.';
          }
          continue;
        }
        heard = true;
        if (pending.isEmpty) waiter = Completer<void>();

        final state = (status['status'] ?? '').toString();
        final message = (status['message'] ?? '').toString();
        if (state == 'up_to_date') {
          return message.isEmpty ? 'Already on the latest version' : message;
        }
        if (state == 'update_available' && !updateSent) {
          updateSent = true;
          _publish(client, {'type': 'ota_update'});
          continue;
        }
        if (state == 'error') {
          return message.isEmpty ? 'Update failed' : message;
        }
        if (state == 'complete') {
          return message.isEmpty ? 'Dashboard updated' : message;
        }
      }
      return 'Update did not finish';
    } catch (_) {
      return 'Cannot reach the local update service';
    } finally {
      await updates?.cancel();
      client.disconnect();
    }
  }

  void _publish(MqttServerClient client, Map<String, dynamic> command) {
    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(command));
    client.publishMessage(
      _commandTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
}

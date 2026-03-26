/// Represents an AHU unit in the hospital
class AhuUnit {
  final String id;           // Internal unique key (e.g., "ahu-01@site/room")
  final String rawId;        // MQTT AHU topic id segment (e.g., "ahu-01")
  final String name;         // Display name
  final String site;         // Hospital site (e.g., "hospitalA")
  final String room;         // Room location (e.g., "icu1")
  final String org;          // Organization (e.g., "almed")
  
  AhuUnit({
    required this.id,
    String? rawId,
    required this.name,
    required this.site,
    required this.room,
    required this.org,
  }) : rawId = rawId ?? id;

  /// Get the MQTT base topic for this AHU
  String get baseTopic => '$org/ahu/$site/$room/$rawId';

  /// Get telemetry topic
  String get telemetryTopic => '$baseTopic/telemetry';

  /// Get state topic
  String get stateTopic => '$baseTopic/state';

  /// Get log topic
  String get logTopic => '$baseTopic/log';

  /// Get command topic
  String get cmdTopic => '$baseTopic/cmd';

  /// Get status topic
  String get statusTopic => '$baseTopic/status';

  /// Get WiFi provisioning topic
  String get provWifiTopic => '$baseTopic/provision/wifi';

  /// Get broker provisioning topic
  String get provBrokerTopic => '$baseTopic/provision/broker';

  /// Get motor timings provisioning topic
  String get provMotorTimingsTopic => '$baseTopic/provision/motor_timings';

  /// Get provisioning acknowledgment topic
  String get provAckTopic => '$baseTopic/provision/ack';

  /// Create from JSON
  factory AhuUnit.fromJson(Map<String, dynamic> json) {
    return AhuUnit(
      id: json['id'] as String,
      rawId: (json['rawId'] ?? json['id']) as String,
      name: json['name'] as String,
      site: json['site'] as String,
      room: json['room'] as String,
      org: json['org'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawId': rawId,
      'name': name,
      'site': site,
      'room': room,
      'org': org,
    };
  }
}



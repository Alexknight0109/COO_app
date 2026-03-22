import 'package:json_annotation/json_annotation.dart';

part 'ahu_state.g.dart';

/// State data from ESP32 AHU unit (retained MQTT message)
@JsonSerializable()
class AhuState {
  final bool run;            // System running state
  final bool m1;             // Motor-1 status
  final bool m2;             // Motor-2 status
  final bool cp;             // Compressor 1 status
  @JsonKey(name: 'cp2') final bool? cp2;  // Compressor 2 status
  @JsonKey(name: 'cpMode') final String? cpMode;  // CP mode: "dual" or "single"
  @JsonKey(name: 'cpActive') final int? cpActive;  // Active CP: 1 or 2
  final bool heater;         // Heater status
  final bool fan;             // Fan status (on/off)
  @JsonKey(name: 'fanSpeed') final int fanSpeed;  // Fan speed: 0=OFF, 1=LOW, 2=MED, 3=HIGH
  final double tempSet;      // Temperature setpoint
  final double humSet;       // Humidity setpoint
  final String ip;           // ESP32 IP address
  @JsonKey(name: 'onlineMode') final bool? onlineMode;  // Operation mode: true=online/cloud, false=offline/local
  
  // Firmware version from ESP32
  final String? version;
  
  // Motor timings (in seconds)
  @JsonKey(name: 'm1_start') final int? m1Start;
  @JsonKey(name: 'm1_post') final int? m1Post;
  @JsonKey(name: 'm2_interval') final int? m2Interval;
  @JsonKey(name: 'm2_run') final int? m2Run;
  @JsonKey(name: 'm2_delay') final int? m2Delay;

  AhuState({
    required this.run,
    required this.m1,
    required this.m2,
    required this.cp,
    this.cp2,
    this.cpMode,
    this.cpActive,
    required this.heater,
    required this.fan,
    required this.fanSpeed,
    required this.tempSet,
    required this.humSet,
    required this.ip,
    this.onlineMode,
    this.version,
    this.m1Start,
    this.m1Post,
    this.m2Interval,
    this.m2Run,
    this.m2Delay,
  });

  factory AhuState.fromJson(Map<String, dynamic> json) =>
      _$AhuStateFromJson(json);

  Map<String, dynamic> toJson() => _$AhuStateToJson(this);
  
  /// Get M2 wait time (interval - run time) for UI display
  /// ESP32 sends actual interval, but UI shows wait time between cycles
  int get m2WaitTime {
    if (m2Interval == null || m2Run == null) return 30;
    // Convert actual interval back to wait time
    return (m2Interval! - m2Run!).clamp(1, 999);
  }

  /// Get fan speed display string
  String get fanSpeedDisplay {
    switch (fanSpeed) {
      case 0:
        return 'OFF';
      case 1:
        return 'LOW (5V)';
      case 2:
        return 'MED (7V)';
      case 3:
        return 'HIGH (9V)';
      default:
        return 'UNKNOWN';
    }
  }
}



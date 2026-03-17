import 'package:json_annotation/json_annotation.dart';

part 'ahu_log.g.dart';

/// Log message from ESP32 AHU unit
@JsonSerializable()
class AhuLog {
  final int ts;              // Timestamp (millis)
  final String lvl;          // Log level (INFO, WARN, ERROR)
  final String msg;          // Log message

  AhuLog({
    required this.ts,
    required this.lvl,
    required this.msg,
  });

  factory AhuLog.fromJson(Map<String, dynamic> json) =>
      _$AhuLogFromJson(json);

  Map<String, dynamic> toJson() => _$AhuLogToJson(this);

  /// Get formatted timestamp
  String get formattedTime {
    final seconds = ts ~/ 1000;
    final hours = (seconds ~/ 3600) % 24;
    final minutes = (seconds ~/ 60) % 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}



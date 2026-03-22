import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ahu_telemetry.dart';
import '../models/ahu_state.dart';
import '../providers/app_provider.dart';

/// Optimized sensor display that only rebuilds when data changes
class OptimizedSensorDisplay extends StatelessWidget {
  final String ahuId;

  const OptimizedSensorDisplay({super.key, required this.ahuId});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, _SensorData>(
      selector: (_, provider) => _SensorData(
        telemetry: provider.getTelemetry(ahuId),
        state: provider.getState(ahuId),
      ),
      builder: (context, data, child) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sensor Readings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.thermostat,
                        label: 'Temperature',
                        value: data.telemetry?.tempDisplay ?? 'N/A',
                        setpoint: data.state != null
                            ? '${data.state!.tempSet.toStringAsFixed(1)}°C'
                            : null,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        value: data.telemetry?.humDisplay ?? 'N/A',
                        setpoint: data.state != null
                            ? '${data.state!.humSet.toStringAsFixed(1)}%'
                            : null,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    String? setpoint,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          if (setpoint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Setpoint: $setpoint',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorData {
  final AhuTelemetry? telemetry;
  final AhuState? state;

  _SensorData({required this.telemetry, required this.state});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SensorData &&
          runtimeType == other.runtimeType &&
          telemetry == other.telemetry &&
          state == other.state;

  @override
  int get hashCode => telemetry.hashCode ^ state.hashCode;
}


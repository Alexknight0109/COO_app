import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/ahu_unit.dart';
import '../../models/ahu_telemetry.dart';
import '../../models/ahu_state.dart';

/// Devices Page - Monitor and control all devices
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2640),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity( 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor and control all AHU devices',
                      style: TextStyle(
                        color: Colors.white.withOpacity( 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Devices List
        Expanded(
          child: Container(
            color: const Color(0xFF141B2D),
            child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              final devices = provider.ahuUnits;
              
              if (devices.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2640),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity( 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.devices_outlined,
                          size: 64,
                          color: Colors.white.withOpacity( 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No devices configured',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Devices will appear here when connected',
                          style: TextStyle(
                            color: Colors.white.withOpacity( 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final telemetry = provider.getTelemetry(device.id);
                  final state = provider.getState(device.id);
                  
                  return _DeviceCard(
                    device: device,
                    telemetry: telemetry,
                    state: state,
                    provider: provider,
                  );
                },
              );
            },
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final AhuUnit device;
  final AhuTelemetry? telemetry;
  final AhuState? state;
  final AppProvider provider;

  const _DeviceCard({
    required this.device,
    required this.telemetry,
    required this.state,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = telemetry != null;
    final isRunning = state?.run ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2640),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity( 0.1),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isOnline 
                ? Colors.green.withOpacity( 0.1)
                : Colors.grey.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isOnline ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
          title: Text(
            device.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${device.id}',
                style: TextStyle(
                  color: Colors.white.withOpacity( 0.7),
                  fontSize: 13,
                ),
              ),
              Text(
                'Location: ${device.site}/${device.room}',
                style: TextStyle(
                  color: Colors.white.withOpacity( 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline 
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                      shape: BoxShape.circle,
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity( 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOnline 
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  if (isRunning) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Running',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        children: [
          if (telemetry != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Temperature',
                          value: telemetry!.temp != null 
                              ? '${telemetry!.temp!.toStringAsFixed(1)}°C'
                              : 'N/A',
                          icon: Icons.thermostat_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetricTile(
                          label: 'Humidity',
                          value: telemetry!.hum != null
                              ? '${telemetry!.hum!.toStringAsFixed(1)}%'
                              : 'N/A',
                          icon: Icons.water_drop_rounded,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetricTile(
                          label: 'Fan Speed',
                          value: '${telemetry!.fanSpeed}',
                          icon: Icons.air_rounded,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity( 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => provider.startAhu(device.id),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity( 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => provider.stopAhu(device.id),
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Device is offline',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity( 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity( 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity( 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}



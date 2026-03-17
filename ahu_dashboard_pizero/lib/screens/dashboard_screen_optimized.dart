import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../models/ahu_unit.dart';
import '../providers/app_provider.dart';
import 'ahu_control_screen.dart';
import 'admin_screen.dart';

/// Optimized dashboard with better performance
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AHU Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Connection status - only rebuilds on connection change
          Selector<AppProvider, bool>(
            selector: (_, provider) => provider.isConnected,
            builder: (context, isConnected, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
          // Admin button - only shows for admin
          Selector<AppProvider, UserRole?>(
            selector: (_, provider) => provider.currentRole,
            builder: (context, role, child) {
              if (role == UserRole.admin) {
                return IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Selector<AppProvider, List<AhuUnit>>(
        selector: (_, provider) => provider.ahuUnits,
        builder: (context, ahus, child) {
          if (ahus.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.air, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No AHU units configured',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: ahus.length,
            itemBuilder: (context, index) {
              return _AhuCard(ahu: ahus[index]);
            },
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }
}

/// Separate widget for AHU card - only rebuilds when its data changes
class _AhuCard extends StatelessWidget {
  final AhuUnit ahu;

  const _AhuCard({required this.ahu});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, _AhuCardData>(
      selector: (_, provider) => _AhuCardData(
        telemetry: provider.getTelemetry(ahu.id),
        state: provider.getState(ahu.id),
        status: provider.getStatus(ahu.id),
      ),
      builder: (context, data, child) {
        final isOnline = data.status == 'online';
        final isRunning = data.state?.run ?? false;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AhuControlScreen(ahuId: ahu.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ahu.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ahu.room.toUpperCase()} • ${ahu.site}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(isOnline: isOnline),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sensor readings
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _SensorReading(
                            icon: Icons.thermostat,
                            label: 'Temperature',
                            value: data.telemetry?.tempDisplay ?? 'N/A',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SensorReading(
                            icon: Icons.water_drop,
                            label: 'Humidity',
                            value: data.telemetry?.humDisplay ?? 'N/A',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status chips
                  Wrap(
                    spacing: 8,
                    children: [
                      _StatusChip('Running', isRunning, Colors.green),
                      _StatusChip('CP', data.state?.cp ?? false, Colors.blue),
                      _StatusChip('Heater', data.state?.heater ?? false, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Data class for AHU card to optimize rebuilds
class _AhuCardData {
  final telemetry;
  final state;
  final String? status;

  _AhuCardData({
    required this.telemetry,
    required this.state,
    required this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AhuCardData &&
          runtimeType == other.runtimeType &&
          telemetry == other.telemetry &&
          state == other.state &&
          status == other.status;

  @override
  int get hashCode => telemetry.hashCode ^ state.hashCode ^ status.hashCode;
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final bool isOnline;

  const _StatusBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOnline ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sensor reading widget
class _SensorReading extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SensorReading({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip widget
class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;

  const _StatusChip(this.label, this.isActive, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.grey,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? color : Colors.grey,
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ahu_state.dart';
import '../providers/app_provider.dart';

/// Control panel for AHU operations - optimized for RPi
class ControlPanel extends StatelessWidget {
  final String ahuId;
  final AhuState? state;

  const ControlPanel({
    super.key,
    required this.ahuId,
    this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = state?.run ?? false;
    final canSendCommands = context.watch<AppProvider>().canSendCommands;

    return Card(
      elevation: 2, // RPi: Reduced elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // RPi: Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Control Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // RPi: Wrap each section in RepaintBoundary
            RepaintBoundary(
              child: _StartStopButton(ahuId: ahuId, isRunning: isRunning, canSendCommands: canSendCommands),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              child: _SetpointControls(ahuId: ahuId, state: state, canSendCommands: canSendCommands),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              child: _FanControl(ahuId: ahuId, state: state, canSendCommands: canSendCommands),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              child: _CpModeControl(ahuId: ahuId, state: state, canSendCommands: canSendCommands),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartStopButton extends StatelessWidget {
  final String ahuId;
  final bool isRunning;
  final bool canSendCommands;
  
  const _StartStopButton({
    required this.ahuId,
    required this.isRunning,
    required this.canSendCommands,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        onPressed: canSendCommands
            ? () => context.read<AppProvider>().toggleAhu(ahuId)
            : null,
        icon: Icon(isRunning ? Icons.stop : Icons.play_arrow, size: 32),
        label: Text(
          isRunning ? 'STOP SYSTEM' : 'START SYSTEM',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isRunning ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _SetpointControls extends StatelessWidget {
  final String ahuId;
  final AhuState? state;
  final bool canSendCommands;
  
  const _SetpointControls({
    required this.ahuId,
    required this.state,
    required this.canSendCommands,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SetpointControl(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: state?.tempSet ?? 22.0,
            unit: '°C',
            min: 15.0,
            max: 30.0,
            color: Colors.orange,
            onChanged: canSendCommands
                ? (value) => context.read<AppProvider>().setTemperature(ahuId, value)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SetpointControl(
            icon: Icons.water_drop,
            label: 'Humidity',
            value: state?.humSet ?? 55.0,
            unit: '%',
            min: 30.0,
            max: 80.0,
            color: Colors.blue,
            onChanged: canSendCommands
                ? (value) => context.read<AppProvider>().setHumidity(ahuId, value)
                : null,
          ),
        ),
      ],
    );
  }
}

class _SetpointControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double>? onChanged;
  
  const _SetpointControl({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onChanged != null && value > min
                    ? () => onChanged!(value - 0.5)
                    : null,
                icon: const Icon(Icons.remove_circle),
                color: color,
                iconSize: 32,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onChanged != null && value < max
                    ? () => onChanged!(value + 0.5)
                    : null,
                icon: const Icon(Icons.add_circle),
                color: color,
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FanControl extends StatelessWidget {
  final String ahuId;
  final AhuState? state;
  final bool canSendCommands;
  
  const _FanControl({
    required this.ahuId,
    required this.state,
    required this.canSendCommands,
  });

  String _getFanSpeedLabel(int speed) {
    switch (speed) {
      case 0: return 'OFF';
      case 1: return 'LOW (5V)';
      case 2: return 'MED (7V)';
      case 3: return 'HIGH (9V)';
      default: return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSpeed = state?.fanSpeed ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.air, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text(
                'Fan Control',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current: ${_getFanSpeedLabel(currentSpeed)}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FanSpeedButton(
                ahuId: ahuId,
                label: 'OFF',
                speed: 0,
                isSelected: currentSpeed == 0,
                color: Colors.grey,
                canSendCommands: canSendCommands,
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                ahuId: ahuId,
                label: 'LOW',
                speed: 1,
                isSelected: currentSpeed == 1,
                color: Colors.green.shade300,
                canSendCommands: canSendCommands,
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                ahuId: ahuId,
                label: 'MID',
                speed: 2,
                isSelected: currentSpeed == 2,
                color: Colors.green.shade600,
                canSendCommands: canSendCommands,
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                ahuId: ahuId,
                label: 'HIGH',
                speed: 3,
                isSelected: currentSpeed == 3,
                color: Colors.green.shade900,
                canSendCommands: canSendCommands,
              ),
            ].map((child) => Expanded(child: child)).toList(),
          ),
        ],
      ),
    );
  }
}

class _FanSpeedButton extends StatelessWidget {
  final String ahuId;
  final String label;
  final int speed;
  final bool isSelected;
  final Color color;
  final bool canSendCommands;
  
  const _FanSpeedButton({
    required this.ahuId,
    required this.label,
    required this.speed,
    required this.isSelected,
    required this.color,
    required this.canSendCommands,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: canSendCommands && !isSelected
          ? () => context.read<AppProvider>().setFanSpeed(ahuId, speed)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CpModeControl extends StatelessWidget {
  final String ahuId;
  final AhuState? state;
  final bool canSendCommands;
  
  const _CpModeControl({
    required this.ahuId,
    required this.state,
    required this.canSendCommands,
  });

  @override
  Widget build(BuildContext context) {
    final cpMode = state?.cpMode ?? "dual";
    final isDualMode = cpMode == "dual";
    final cpActive = state?.cpActive ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.ac_unit, color: Colors.cyan, size: 32),
              SizedBox(width: 12),
              Text(
                'CP Mode Control',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isDualMode 
                ? 'Current: DUAL (Auto-switch every hour)'
                : 'Current: SINGLE (CP$cpActive only)',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canSendCommands && !isDualMode
                      ? () => context.read<AppProvider>().setCpMode(ahuId, "dual")
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDualMode ? Colors.cyan : Colors.grey.shade200,
                    foregroundColor: isDualMode ? Colors.white : Colors.grey.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'DUAL',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: canSendCommands && isDualMode
                      ? () => context.read<AppProvider>().setCpMode(ahuId, "single")
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isDualMode ? Colors.teal : Colors.grey.shade200,
                    foregroundColor: !isDualMode ? Colors.white : Colors.grey.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'SINGLE (CP$cpActive)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          if (!isDualMode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canSendCommands && cpActive != 1
                        ? () => context.read<AppProvider>().setCpActive(ahuId, 1)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cpActive == 1 ? Colors.cyan : Colors.grey.shade200,
                      foregroundColor: cpActive == 1 ? Colors.white : Colors.grey.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Use CP1',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canSendCommands && cpActive != 2
                        ? () => context.read<AppProvider>().setCpActive(ahuId, 2)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cpActive == 2 ? Colors.teal : Colors.grey.shade200,
                      foregroundColor: cpActive == 2 ? Colors.white : Colors.grey.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Use CP2',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

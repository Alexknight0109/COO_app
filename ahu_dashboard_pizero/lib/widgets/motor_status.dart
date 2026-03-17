import 'package:flutter/material.dart';
import '../models/ahu_state.dart';

/// Widget to display motor and component status
class MotorStatus extends StatelessWidget {
  final AhuState? state;

  const MotorStatus({super.key, this.state});

  String _getFanLabel(int fanSpeed) {
    switch (fanSpeed) {
      case 0: return 'Fan (OFF)';
      case 1: return 'Fan (LOW)';
      case 2: return 'Fan (MID)';
      case 3: return 'Fan (HIGH)';
      default: return 'Fan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Component Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatusIndicator(
                  icon: Icons.cleaning_services,
                  label: 'Motor 1 (Filter)',
                  isActive: state?.m1 ?? false,
                  color: Colors.blue,
                ),
                _StatusIndicator(
                  icon: Icons.water,
                  label: 'Motor 2 (Drain)',
                  isActive: state?.m2 ?? false,
                  color: Colors.purple,
                ),
                _StatusIndicator(
                  icon: Icons.ac_unit,
                  label: 'CP1 (Compressor 1)',
                  isActive: state?.cp ?? false,
                  color: Colors.cyan,
                ),
                _StatusIndicator(
                  icon: Icons.ac_unit,
                  label: 'CP2 (Compressor 2)',
                  isActive: state?.cp2 ?? false,
                  color: Colors.teal,
                ),
                _StatusIndicator(
                  icon: Icons.whatshot,
                  label: 'Heater',
                  isActive: state?.heater ?? false,
                  color: Colors.orange,
                ),
                _StatusIndicator(
                  icon: Icons.air,
                  label: _getFanLabel(state?.fanSpeed ?? 0),
                  isActive: state?.fan ?? false,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  
  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isActive ? color : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(isActive ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: activeColor, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
              Text(
                isActive ? 'ACTIVE' : 'IDLE',
                style: TextStyle(fontSize: 11, color: activeColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

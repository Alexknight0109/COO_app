import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../services/motor_timing_storage.dart';

/// Motor timing adjustment dialog
class MotorTimingDialog extends StatefulWidget {
  final String ahuId;
  final String motorLabel;

  const MotorTimingDialog({
    super.key,
    required this.ahuId,
    required this.motorLabel,
  });

  @override
  State<MotorTimingDialog> createState() => _MotorTimingDialogState();
}

class _MotorTimingDialogState extends State<MotorTimingDialog> {
  int _m1Start = 10;
  int _m1Post = 10;
  int _m2Interval = 30;
  int _m2Run = 10;
  int _m2Delay = 5;

  @override
  void initState() {
    super.initState();
    _loadTimings();
  }
  
  Future<void> _loadTimings() async {
    final savedTimings = await MotorTimingStorage.loadTimings(widget.ahuId);
    
    if (savedTimings != null) {
      setState(() {
        _m1Start = savedTimings['m1_start']!;
        _m1Post = savedTimings['m1_post']!;
        _m2Interval = savedTimings['m2_wait']!;
        _m2Run = savedTimings['m2_run']!;
        _m2Delay = savedTimings['m2_delay']!;
      });
      debugPrint('MotorTimingDialog: Loaded from local storage');
      return;
    }
    
    if (mounted) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final state = provider.getState(widget.ahuId);
      if (state != null && state.m1Start != null) {
        setState(() {
          _m1Start = state.m1Start ?? 10;
          _m1Post = state.m1Post ?? 10;
          _m2Interval = state.m2WaitTime;
          _m2Run = state.m2Run ?? 10;
          _m2Delay = state.m2Delay ?? 5;
        });
        debugPrint('MotorTimingDialog: Loaded from ESP32 state');
        return;
      }
    }
    
    debugPrint('MotorTimingDialog: Using default values');
  }

  void _resetToDefaults() {
    setState(() {
      _m1Start = 10;
      _m1Post = 10;
      _m2Interval = 30;
      _m2Run = 10;
      _m2Delay = 5;
    });
  }

  Future<void> _saveTimings() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    await MotorTimingStorage.saveTimings(
      widget.ahuId,
      m1Start: _m1Start,
      m1Post: _m1Post,
      m2WaitTime: _m2Interval,
      m2Run: _m2Run,
      m2Delay: _m2Delay,
    );
    
    provider.provisionMotorTimings(
      widget.ahuId,
      m1Start: _m1Start,
      m1Post: _m1Post,
      m2Interval: _m2Interval,
      m2Run: _m2Run,
      m2Delay: _m2Delay,
    );
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Motor timings saved! Wait: ${_m2Interval}s, Run: ${_m2Run}s'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                : [Colors.white, Colors.blue.shade50],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(motorLabel: widget.motorLabel),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _TimingControl(
                      icon: Icons.play_circle_rounded,
                      label: 'Motor-1 Start Run',
                      value: _m1Start,
                      unit: 's',
                      color: AppTheme.lightPrimary,
                      onIncrement: () => setState(() => _m1Start = (_m1Start + 1).clamp(1, 999)),
                      onDecrement: () => setState(() => _m1Start = (_m1Start - 1).clamp(1, 999)),
                      helpText: 'Duration Motor-1 runs after system starts',
                    ),
                    const SizedBox(height: 16),
                    _TimingControl(
                      icon: Icons.stop_circle_rounded,
                      label: 'Motor-1 Post Run',
                      value: _m1Post,
                      unit: 's',
                      color: AppTheme.lightPrimary,
                      onIncrement: () => setState(() => _m1Post = (_m1Post + 1).clamp(1, 999)),
                      onDecrement: () => setState(() => _m1Post = (_m1Post - 1).clamp(1, 999)),
                      helpText: 'Duration Motor-1 runs during shutdown',
                    ),
                    const SizedBox(height: 16),
                    _TimingControl(
                      icon: Icons.refresh_rounded,
                      label: 'Motor-2 Wait Time',
                      value: _m2Interval,
                      unit: 's',
                      color: AppTheme.humidity,
                      onIncrement: () => setState(() => _m2Interval = (_m2Interval + 1).clamp(1, 999)),
                      onDecrement: () => setState(() => _m2Interval = (_m2Interval - 1).clamp(1, 999)),
                      helpText: 'Wait time between Motor-2 cycles',
                    ),
                    const SizedBox(height: 16),
                    _TimingControl(
                      icon: Icons.schedule_rounded,
                      label: 'Motor-2 Run Time',
                      value: _m2Run,
                      unit: 's',
                      color: AppTheme.humidity,
                      onIncrement: () => setState(() => _m2Run = (_m2Run + 1).clamp(1, 999)),
                      onDecrement: () => setState(() => _m2Run = (_m2Run - 1).clamp(1, 999)),
                      helpText: 'Duration Motor-2 runs each cycle',
                    ),
                    const SizedBox(height: 16),
                    _TimingControl(
                      icon: Icons.hourglass_empty_rounded,
                      label: 'Motor-2 Delay',
                      value: _m2Delay,
                      unit: 's',
                      color: AppTheme.info,
                      onIncrement: () => setState(() => _m2Delay = (_m2Delay + 1).clamp(1, 999)),
                      onDecrement: () => setState(() => _m2Delay = (_m2Delay - 1).clamp(1, 999)),
                      helpText: 'Delay after Motor-1 stops',
                    ),
                  ],
                ),
              ),
            ),
            _DialogActions(
              onReset: _resetToDefaults,
              onSave: _saveTimings,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String motorLabel;
  
  const _DialogHeader({required this.motorLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.lightPrimary, AppTheme.lightPrimary.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motor Timing Configuration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  motorLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onSave;
  
  const _DialogActions({required this.onReset, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.lightPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Timings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final String unit;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String helpText;

  const _TimingControl({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
    required this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withOpacity(0.15), color.withOpacity(0.2)]
              : [color.withOpacity(0.08), color.withOpacity(0.12)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            helpText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: value > 1 ? onDecrement : null,
                icon: const Icon(Icons.remove_circle_rounded),
                color: color,
                iconSize: 40,
              ),
              const SizedBox(width: 12),
              Text(
                '$value$unit',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: value < 999 ? onIncrement : null,
                icon: const Icon(Icons.add_circle_rounded),
                color: color,
                iconSize: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

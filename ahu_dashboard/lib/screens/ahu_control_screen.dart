import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_role.dart';
import '../models/ahu_telemetry.dart';
import '../models/ahu_state.dart';
import '../models/ahu_log.dart';
import '../widgets/motor_timing_dialog.dart';
import '../widgets/wifi_control_widget.dart';
import '../widgets/screen_lock_dialog.dart';

/// Modern AHU control screen
class AhuControlScreen extends StatefulWidget {
  final String ahuId;

  const AhuControlScreen({super.key, required this.ahuId});

  @override
  State<AhuControlScreen> createState() => _AhuControlScreenState();
}

class _AhuControlScreenState extends State<AhuControlScreen> {
  bool _showLogs = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF334155),
                  ]
                : [Colors.white, Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _TopBar(ahuId: widget.ahuId, isDark: isDark),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Temperature & Humidity
                      _SensorControls(ahuId: widget.ahuId),
                      const SizedBox(height: 16),
                      // Compact AQI & HEPA boxes (tap to expand) - combo sensors only
                      _ComboSensorBoxes(ahuId: widget.ahuId),
                      // Component Status
                      _ComponentStatus(ahuId: widget.ahuId),
                      const SizedBox(height: 16),
                      // Logs (collapsible) - ADMIN ONLY
                      _LogsWrapper(
                        ahuId: widget.ahuId,
                        isExpanded: _showLogs,
                        onToggle: () => setState(() => _showLogs = !_showLogs),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String ahuId;
  final bool isDark;
  
  const _TopBar({required this.ahuId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Reduced padding for 7-inch Pi display
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ALMED Branding
          Text(
            'ALMED',
            style: TextStyle(
              fontFamily: 'Verdana',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 24,
            color: theme.dividerColor.withOpacity(0.3),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.1),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _AhuInfo(ahuId: ahuId)),
          // Start/Stop toggle
          _StartStopButton(ahuId: ahuId),
          const SizedBox(width: 12),
          // CP Mode toggle
          _CpModeToggleButton(ahuId: ahuId),
          const SizedBox(width: 12),
          // Mode toggle (Admin only)
          _ModeToggleButton(ahuId: ahuId),
          const SizedBox(width: 12),
          // Screen Lock button
          _ScreenLockButton(),
          const SizedBox(width: 12),
          // WiFi control (Admin only)
          _WiFiButton(),
          const SizedBox(width: 12),
          // Reset button (Admin only)
          _ResetButton(ahuId: ahuId),
        ],
      ),
    );
  }
}

class _ScreenLockButton extends StatelessWidget {
  const _ScreenLockButton();

  void _showUnlockDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScreenUnlockDialog(
        onVerify: (passcode) {
          return context.read<AppProvider>().unlockScreen(passcode);
        },
      ),
    );
  }

  void _showChangePasscodeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _ChangePasscodeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, bool>(
      selector: (_, provider) => provider.isScreenLocked,
      builder: (context, isLocked, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: isLocked
                ? const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  )
                : null,
            color: isLocked ? null : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isLocked
                ? null
                : Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isLocked) {
                  _showUnlockDialog(context);
                } else {
                  context.read<AppProvider>().lockScreen();
                }
              },
              // Long press to change passcode (only when unlocked)
              onLongPress: isLocked ? null : () => _showChangePasscodeDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: isLocked ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'LOCKED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dialog to change the screen lock passcode
class _ChangePasscodeDialog extends StatefulWidget {
  const _ChangePasscodeDialog();

  @override
  State<_ChangePasscodeDialog> createState() => _ChangePasscodeDialogState();
}

class _ChangePasscodeDialogState extends State<_ChangePasscodeDialog> {
  String _currentPasscode = '';
  String _newPasscode = '';
  String _confirmPasscode = '';
  int _step = 0; // 0: current, 1: new, 2: confirm
  String? _error;
  bool _isProcessing = false;

  String get _title {
    switch (_step) {
      case 0: return 'Enter Current Passcode';
      case 1: return 'Enter New Passcode';
      case 2: return 'Confirm New Passcode';
      default: return '';
    }
  }

  String get _currentInput {
    switch (_step) {
      case 0: return _currentPasscode;
      case 1: return _newPasscode;
      case 2: return _confirmPasscode;
      default: return '';
    }
  }

  void _onDigitPressed(String digit) {
    if (_isProcessing) return;
    
    setState(() {
      _error = null;
      switch (_step) {
        case 0:
          if (_currentPasscode.length < 6) _currentPasscode += digit;
          break;
        case 1:
          if (_newPasscode.length < 6) _newPasscode += digit;
          break;
        case 2:
          if (_confirmPasscode.length < 6) _confirmPasscode += digit;
          break;
      }
    });

    // Auto-advance when 6 digits entered
    if (_currentInput.length == 6) {
      _handleStepComplete();
    }
  }

  void _onBackspace() {
    if (_isProcessing) return;
    
    setState(() {
      _error = null;
      switch (_step) {
        case 0:
          if (_currentPasscode.isNotEmpty) {
            _currentPasscode = _currentPasscode.substring(0, _currentPasscode.length - 1);
          }
          break;
        case 1:
          if (_newPasscode.isNotEmpty) {
            _newPasscode = _newPasscode.substring(0, _newPasscode.length - 1);
          }
          break;
        case 2:
          if (_confirmPasscode.isNotEmpty) {
            _confirmPasscode = _confirmPasscode.substring(0, _confirmPasscode.length - 1);
          }
          break;
      }
    });
  }

  Future<void> _handleStepComplete() async {
    if (_step == 0) {
      // Move to new passcode step
      setState(() => _step = 1);
    } else if (_step == 1) {
      // Move to confirm step
      setState(() => _step = 2);
    } else if (_step == 2) {
      // Check if new and confirm match
      if (_newPasscode != _confirmPasscode) {
        setState(() {
          _error = 'Passcodes do not match';
          _confirmPasscode = '';
        });
        return;
      }

      // Try to change passcode
      setState(() => _isProcessing = true);
      final success = await context.read<AppProvider>().changeScreenLockPasscode(
        _currentPasscode,
        _newPasscode,
      );
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Passcode changed successfully'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _error = 'Wrong current passcode';
          _currentPasscode = '';
          _newPasscode = '';
          _confirmPasscode = '';
          _step = 0;
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.key_rounded, color: Colors.blue.shade400, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Change Passcode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Step indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index == _step;
                final isComplete = index < _step;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isComplete 
                        ? Colors.green.shade400 
                        : isActive 
                            ? Colors.blue.shade400 
                            : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              _title,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            // Passcode dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final filled = index < _currentInput.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Colors.blue.shade400 : Colors.transparent,
                    border: Border.all(
                      color: filled ? Colors.blue.shade400 : Colors.grey.shade500,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            
            // Error message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 20),
            
            // Numpad
            _buildNumpad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', '⌫']])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((digit) {
                if (digit.isEmpty) {
                  return const SizedBox(width: 70);
                }
                final isBackspace = digit == '⌫';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Material(
                    color: isBackspace ? Colors.grey.shade700 : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: isBackspace ? _onBackspace : () => _onDigitPressed(digit),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 58,
                        height: 50,
                        alignment: Alignment.center,
                        child: isBackspace
                            ? const Icon(Icons.backspace_rounded, color: Colors.white, size: 22)
                            : Text(
                                digit,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// Exit functionality moved to Admin screen only

class _AhuInfo extends StatelessWidget {
  final String ahuId;
  
  const _AhuInfo({required this.ahuId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Selector<AppProvider, ({String name, bool isOnline, bool isRunning, bool isCloudConnected, String? version})>(
      selector: (_, provider) {
        final ahu = provider.ahuUnits.firstWhere((a) => a.id == ahuId);
        final status = provider.getStatus(ahuId);
        final state = provider.getState(ahuId);
        final awsConnected = provider.isAwsConnected(ahuId);
        return (
          name: ahu.name,
          isOnline: status == 'online',
          isRunning: state?.run ?? false,
          isCloudConnected: awsConnected,
          version: state?.version,
        );
      },
      builder: (context, data, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              data.name,
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 22),
                ),
                if (data.version != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      data.version!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                // Connection Status
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: data.isOnline ? AppTheme.success : AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  data.isOnline ? 'Online' : 'Offline',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                // System Running Status
                _RunningBadge(isRunning: data.isRunning),
                const SizedBox(width: 8),
                // Cloud Connection Status
                _CloudBadge(isConnected: data.isCloudConnected),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RunningBadge extends StatelessWidget {
  final bool isRunning;
  
  const _RunningBadge({required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final color = isRunning ? const Color(0xFF10B981) : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRunning ? color : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRunning ? Icons.power_rounded : Icons.power_off_rounded,
            size: 14,
            color: isRunning ? color : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            isRunning ? 'RUNNING' : 'STOPPED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isRunning ? color : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudBadge extends StatelessWidget {
  final bool isConnected;
  
  const _CloudBadge({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? const Color(0xFF3B82F6) : Colors.grey;  // Blue when connected
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected ? color : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 14,
            color: isConnected ? color : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'CLOUD' : 'OFFLINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isConnected ? color : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartStopButton extends StatelessWidget {
  final String ahuId;
  
  const _StartStopButton({required this.ahuId});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({bool isRunning, bool canSendCommands})>(
      selector: (_, provider) => (
        isRunning: provider.getState(ahuId)?.run ?? false,
        canSendCommands: provider.canSendCommands,
      ),
      builder: (context, data, _) {
        final isRunning = data.isRunning;
        final canSend = data.canSendCommands;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRunning
                  ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                  : const [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canSend ? () {
                context.read<AppProvider>().toggleAhu(ahuId);
              } : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRunning ? 'Stop' : 'Start',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CpModeToggleButton extends StatelessWidget {
  final String ahuId;
  
  const _CpModeToggleButton({required this.ahuId});

  void _showCpSelectionDialog(BuildContext context, String ahuId, int currentCpActive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.ac_unit_rounded, color: Colors.cyan, size: 24),
            SizedBox(width: 12),
            Text('Select Compressor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CpOptionButton(
              context: context,
              ahuId: ahuId,
              cpNumber: 1,
              isSelected: currentCpActive == 1,
              label: 'CP1',
              color: Colors.cyan,
            ),
            const SizedBox(height: 12),
            _CpOptionButton(
              context: context,
              ahuId: ahuId,
              cpNumber: 2,
              isSelected: currentCpActive == 2,
              label: 'CP2',
              color: Colors.teal,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Selector<AppProvider, ({String cpMode, int cpActive, bool canSendCommands, bool isLocked})>(
      selector: (_, provider) {
        final state = provider.getState(ahuId);
        final cpMode = state?.cpMode ?? "dual";
        final cpActive = state?.cpActive ?? 1;
        final canSendCommands = provider.canSendCommands;
        final isLocked = provider.isScreenLocked;
        return (cpMode: cpMode, cpActive: cpActive, canSendCommands: canSendCommands, isLocked: isLocked);
      },
      builder: (context, data, _) {
        final isDualMode = data.cpMode == "dual";
        // CP mode is LOCKED when screen is locked
        final isEnabled = data.canSendCommands && !data.isLocked;

        final isLocked = data.isLocked;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CP Mode Toggle Button - LOCKED when screen is locked
            Container(
              decoration: BoxDecoration(
                gradient: isLocked 
                    ? LinearGradient(
                        colors: [Colors.grey.shade500, Colors.grey.shade600],
                      )
                    : LinearGradient(
                  colors: isDualMode
                      ? [Colors.cyan.shade600, Colors.cyan.shade700]
                      : [Colors.teal.shade600, Colors.teal.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled
                      ? () {
                          final newMode = isDualMode ? "single" : "dual";
                          context.read<AppProvider>().setCpMode(ahuId, newMode);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLocked ? Icons.lock_rounded : Icons.ac_unit_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDualMode ? 'DUAL' : 'SINGLE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Arrow button (only show in single mode)
            if (!isDualMode) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.2),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled
                        ? () => _showCpSelectionDialog(context, ahuId, data.cpActive)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: isEnabled ? Colors.teal : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CpOptionButton extends StatelessWidget {
  final BuildContext context;
  final String ahuId;
  final int cpNumber;
  final bool isSelected;
  final String label;
  final Color color;

  const _CpOptionButton({
    required this.context,
    required this.ahuId,
    required this.cpNumber,
    required this.isSelected,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<AppProvider>().setCpActive(ahuId, cpNumber);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.ac_unit_rounded,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Compressor $cpNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WiFiButton extends StatelessWidget {
  const _WiFiButton();

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, UserRole?>(
      selector: (_, provider) => provider.currentRole,
      builder: (context, role, _) {
        if (role != UserRole.admin) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.wifi_rounded),
            tooltip: 'WiFi Networks',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
                    padding: const EdgeInsets.all(16),
                    child: const WiFiControlWidget(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ResetButton extends StatelessWidget {
  final String ahuId;

  const _ResetButton({required this.ahuId});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, UserRole?>(
      selector: (_, provider) => provider.currentRole,
      builder: (context, role, _) {
        if (role != UserRole.admin) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset ESP32',
            color: Colors.orange,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('Reset ESP32'),
                      ],
                    ),
                    content: const Text(
                      'This will reset the ESP32 device (same as pressing the physical reset button). '
                      'The system will restart and reconnect. Continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          context.read<AppProvider>().resetEsp32(ahuId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reset command sent to ESP32'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  final String ahuId;
  
  const _ModeToggleButton({required this.ahuId});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({bool isAdmin, bool isOnlineMode})>(
      selector: (_, provider) {
        final isAdmin = provider.currentRole == UserRole.admin;
        // Get mode from state (we'll add this to AhuState model)
        final state = provider.getState(ahuId);
        final isOnlineMode = state?.onlineMode ?? true; // Default to online
        return (isAdmin: isAdmin, isOnlineMode: isOnlineMode);
      },
      builder: (context, data, _) {
        if (!data.isAdmin) return const SizedBox.shrink();
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: data.isOnlineMode
                  ? const [Color(0xFF3B82F6), Color(0xFF2563EB)]
                  : const [Color(0xFF6B7280), Color(0xFF4B5563)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<AppProvider>().setMode(
                  ahuId,
                  !data.isOnlineMode, // Toggle mode
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.isOnlineMode ? Icons.cloud_rounded : Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.isOnlineMode ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Data class for sensor controls
@immutable
class _SensorData {
  final AhuTelemetry? telemetry;
  final AhuState? state;

  const _SensorData({required this.telemetry, required this.state});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SensorData &&
          runtimeType == other.runtimeType &&
          telemetry == other.telemetry &&
          state == other.state;

  @override
  int get hashCode => Object.hash(telemetry, state);
}

class _SensorControls extends StatelessWidget {
  final String ahuId;

  const _SensorControls({required this.ahuId});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({_SensorData data, bool canSendCommands, bool isLocked})>(
      selector: (_, provider) => (
        data: _SensorData(
          telemetry: provider.getTelemetry(ahuId),
          state: provider.getState(ahuId),
        ),
        canSendCommands: provider.canSendCommands,
        isLocked: provider.isScreenLocked,
      ),
      builder: (context, result, _) {
        final data = result.data;
        final canSend = result.canSendCommands;
        final isLocked = result.isLocked;
        
        // When locked: humidity is disabled, temperature remains controllable
        final canModifyHumidity = canSend && !isLocked;
        
        return Row(
          children: [
            // Temperature - ALWAYS controllable (even when locked)
            Expanded(
              child: _SensorControl(
                icon: Icons.thermostat_rounded,
                label: 'Temperature',
                actual: data.telemetry?.temp?.toStringAsFixed(1) ?? '--',
                setpoint: data.state?.tempSet ?? 22.0,
                unit: '°C',
                color: AppTheme.temperature,
                min: 15,
                max: 30,
                isLocked: false,  // Temperature never locked
                onChanged: canSend ? (value) {
                  context.read<AppProvider>().setTemperature(ahuId, value);
                } : null,
              ),
            ),
            const SizedBox(width: 16),
            // Humidity - LOCKED when screen is locked
            Expanded(
              child: _SensorControl(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                actual: data.telemetry?.hum?.toStringAsFixed(1) ?? '--',
                setpoint: data.state?.humSet ?? 55.0,
                unit: '%',
                color: AppTheme.humidity,
                min: 30,
                max: 80,
                isLocked: isLocked,
                onChanged: canModifyHumidity ? (value) {
                  context.read<AppProvider>().setHumidity(ahuId, value);
                } : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SensorControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final String actual;
  final double setpoint;
  final String unit;
  final Color color;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final bool isLocked;

  const _SensorControl({
    required this.icon,
    required this.label,
    required this.actual,
    required this.setpoint,
    required this.unit,
    required this.color,
    required this.min,
    required this.max,
    this.onChanged,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withOpacity(0.15), color.withOpacity(0.08)]
              : [Colors.white, color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Icon with glow effect
                _GlowingIcon(icon: icon, color: color),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Large actual value
                _ActualValue(value: actual, unit: unit, color: color),
                const SizedBox(height: 6),
                _Badge(text: 'ACTUAL', color: color),
                const SizedBox(height: 20),
                // Setpoint controls
                _SetpointControls(
                  setpoint: setpoint,
                  unit: unit,
                  color: color,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                  isLocked: isLocked,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  
  const _GlowingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _ActualValue extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  
  const _ActualValue({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [color, color.withOpacity(0.7)],
      ).createShader(bounds),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              unit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SetpointControls extends StatelessWidget {
  final double setpoint;
  final String unit;
  final Color color;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final bool isLocked;
  
  const _SetpointControls({
    required this.setpoint,
    required this.unit,
    required this.color,
    required this.min,
    required this.max,
    this.onChanged,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLocked 
              ? [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)]
              : [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLocked ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLocked) ...[
                Icon(Icons.lock_rounded, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
              ],
          Text(
            'SETPOINT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey.shade500 : color.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlossyButton(
                icon: Icons.remove,
                color: isLocked ? Colors.grey : color,
                onPressed: onChanged != null && setpoint > min ? () => onChanged!(setpoint - 0.5) : null,
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: (isLocked ? Colors.grey : color).withOpacity(0.2), blurRadius: 8),
                  ],
                ),
                child: Text(
                  '${setpoint.toStringAsFixed(1)}$unit',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey : color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _GlossyButton(
                icon: Icons.add,
                color: isLocked ? Colors.grey : color,
                onPressed: onChanged != null && setpoint < max ? () => onChanged!(setpoint + 0.5) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlossyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _GlossyButton({
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
                  )
                : null,
            color: isEnabled ? null : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Data class for component status
@immutable
class _ComponentData {
  final AhuState? state;

  const _ComponentData({required this.state});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ComponentData &&
          runtimeType == other.runtimeType &&
          state == other.state;

  @override
  int get hashCode => state.hashCode;
}

class _ComponentStatus extends StatelessWidget {
  final String ahuId;

  const _ComponentStatus({required this.ahuId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Selector<AppProvider, _ComponentData>(
      selector: (_, provider) => _ComponentData(state: provider.getState(ahuId)),
      builder: (context, data, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _ComponentHeader(isDark: isDark),
              const SizedBox(height: 20),
              _ComponentIndicators(ahuId: ahuId, data: data),
            ],
          ),
        );
      },
    );
  }
}

class _ComponentHeader extends StatelessWidget {
  final bool isDark;
  
  const _ComponentHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.info.withOpacity(0.2), AppTheme.info.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.dashboard_rounded, size: 20, color: AppTheme.info),
        ),
        const SizedBox(width: 12),
        Text(
          'Component Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ComponentIndicators extends StatelessWidget {
  final String ahuId;
  final _ComponentData data;
  
  const _ComponentIndicators({required this.ahuId, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _MotorIndicator(
            ahuId: ahuId,
            icon: Icons.cleaning_services_rounded,
            label: 'Motor 1 (Filter)',
            isActive: data.state?.m1 ?? false,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          _MotorIndicator(
            ahuId: ahuId,
            icon: Icons.water_rounded,
            label: 'Motor 2 (Drain)',
            isActive: data.state?.m2 ?? false,
            color: const Color(0xFF60A5FA),
          ),
          const SizedBox(width: 12),
          // CP indicators - show both in DUAL mode, only selected in SINGLE mode
          ...() {
            final cpMode = data.state?.cpMode ?? "dual";
            final cpActive = data.state?.cpActive ?? 1;
            final isDualMode = cpMode == "dual";
            
            if (isDualMode) {
              // DUAL mode: show both CP1 and CP2
              return [
                _StatusIndicator(
                  icon: Icons.ac_unit_rounded,
                  label: 'CP1',
                  isActive: data.state?.cp ?? false,
                  color: Colors.cyan,
                ),
                const SizedBox(width: 12),
                _StatusIndicator(
                  icon: Icons.ac_unit_rounded,
                  label: 'CP2',
                  isActive: data.state?.cp2 ?? false,
                  color: Colors.teal,
                ),
              ];
            } else {
              // SINGLE mode: show only the active CP
              if (cpActive == 1) {
                return [
                  _StatusIndicator(
                    icon: Icons.ac_unit_rounded,
                    label: 'CP1',
                    isActive: data.state?.cp ?? false,
                    color: Colors.cyan,
                  ),
                ];
              } else {
                return [
                  _StatusIndicator(
                    icon: Icons.ac_unit_rounded,
                    label: 'CP2',
                    isActive: data.state?.cp2 ?? false,
                    color: Colors.teal,
                  ),
                ];
              }
            }
          }(),
          const SizedBox(width: 12),
          _StatusIndicator(
            icon: Icons.whatshot_rounded,
            label: 'Heater',
            isActive: data.state?.heater ?? false,
            color: const Color(0xFF1E40AF),
          ),
          const SizedBox(width: 12),
          _FanIndicator(ahuId: ahuId, data: data),
        ],
      ),
    );
  }
}

class _MotorIndicator extends StatelessWidget {
  final String ahuId;
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  
  const _MotorIndicator({
    required this.ahuId,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, bool>(
      selector: (_, provider) => provider.currentRole == UserRole.admin,
      builder: (context, isAdmin, _) {
        return GestureDetector(
          onTap: isAdmin
              ? () => showDialog(
                  context: context,
                  builder: (context) => MotorTimingDialog(
                    ahuId: ahuId,
                    motorLabel: 'Motor 1 & 2 Timing',
                  ),
                )
              : null,
          child: _StatusIndicator(
            icon: icon,
            label: label,
            isActive: isActive,
            color: color,
            isClickable: isAdmin,
          ),
        );
      },
    );
  }
}

class _FanIndicator extends StatelessWidget {
  final String ahuId;
  final _ComponentData data;
  
  const _FanIndicator({required this.ahuId, required this.data});

  String _getFanLabel(int? fanSpeed) {
    switch (fanSpeed ?? 0) {
      case 0: return 'Fan (OFF)';
      case 1: return 'Fan (LOW)';
      case 2: return 'Fan (MID)';
      case 3: return 'Fan (HIGH)';
      default: return 'Fan (OFF)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({bool canSendCommands, bool isRunning})>(
      selector: (_, provider) => (
        canSendCommands: provider.canSendCommands,
        isRunning: data.state?.run ?? false,
      ),
      builder: (context, info, _) {
        final canToggle = info.canSendCommands && info.isRunning;
        return GestureDetector(
          onTap: canToggle ? () => context.read<AppProvider>().toggleFanSpeed(ahuId) : null,
          child: _StatusIndicator(
            icon: Icons.air_rounded,
            label: _getFanLabel(data.state?.fanSpeed),
            isActive: data.state?.fan ?? false,
            color: const Color(0xFF10B981),
            isClickable: canToggle,
          ),
        );
      },
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final bool isClickable;

  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.25), color.withOpacity(0.15)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
                      : [Colors.white.withOpacity(0.9), Colors.grey.shade50],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? color.withOpacity(0.5)
                : Theme.of(context).dividerColor.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IndicatorIcon(icon: icon, isActive: isActive, color: color, isDark: isDark),
                  const SizedBox(height: 8),
                  _IndicatorLabel(label: label, isActive: isActive, color: color, isDark: isDark),
                  const SizedBox(height: 6),
                  _IndicatorBadge(isActive: isActive, color: color),
                  if (isClickable) ...[
                    const SizedBox(height: 4),
                    Icon(Icons.touch_app, size: 10, color: AppTheme.info.withOpacity(0.6)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicatorIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color color;
  final bool isDark;
  
  const _IndicatorIcon({
    required this.icon,
    required this.isActive,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
            : null,
      ),
      child: Icon(
        icon,
        color: isActive ? color : (isDark ? Colors.white.withOpacity(0.4) : Colors.black54),
        size: 22,
      ),
    );
  }
}

class _IndicatorLabel extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final bool isDark;
  
  const _IndicatorLabel({
    required this.label,
    required this.isActive,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: isActive ? color : (isDark ? Colors.white.withOpacity(0.7) : Colors.black87),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _IndicatorBadge extends StatelessWidget {
  final bool isActive;
  final Color color;
  
  const _IndicatorBadge({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Text(
        isActive ? 'ON' : 'OFF',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: isActive ? color : Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _LogsWrapper extends StatelessWidget {
  final String ahuId;
  final bool isExpanded;
  final VoidCallback onToggle;
  
  const _LogsWrapper({
    required this.ahuId,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, bool>(
      selector: (_, provider) => provider.currentRole == UserRole.admin,
      builder: (context, isAdmin, _) {
        if (!isAdmin) return const SizedBox.shrink();
        
        return Column(
          children: [
            _LogsSection(
              ahuId: ahuId,
              isExpanded: isExpanded,
              onToggle: onToggle,
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _LogsSection extends StatelessWidget {
  final String ahuId;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _LogsSection({
    required this.ahuId,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.article_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'System Logs',
                        style: theme.textTheme.displayMedium?.copyWith(fontSize: 18),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) _LogsList(ahuId: ahuId),
        ],
      ),
    );
  }
}

class _LogsList extends StatelessWidget {
  final String ahuId;
  
  const _LogsList({required this.ahuId});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, List<AhuLog>>(
      selector: (_, provider) => provider.getLogs(ahuId),
      builder: (context, logs, _) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: logs.isEmpty
              ? Center(
                  child: Text(
                    'No logs available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[logs.length - 1 - index];
                    return _LogItem(log: log);
                  },
                ),
        );
      },
    );
  }
}

class _LogItem extends StatelessWidget {
  final AhuLog log;
  
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            log.lvl == 'ERROR'
                ? Icons.error_rounded
                : log.lvl == 'WARN'
                    ? Icons.warning_rounded
                    : Icons.info_rounded,
            size: 16,
            color: log.lvl == 'ERROR'
                ? AppTheme.error
                : AppTheme.info,
          ),
          const SizedBox(width: 8),
          Text(
            log.formattedTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.msg,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ PM READINGS & HEPA STATUS (Combo Sensors Only) ============
// Optimized for 7-inch 1024x600 Pi display

/// PM readings row (large) + HEPA box below (expandable)
class _ComboSensorBoxes extends StatelessWidget {
  final String ahuId;

  const _ComboSensorBoxes({required this.ahuId});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, AhuTelemetry?>(
      selector: (_, provider) => provider.getTelemetry(ahuId),
      builder: (context, telemetry, _) {
        if (telemetry == null) return const SizedBox.shrink();
        
        final hasAqi = telemetry.hasAirQualityData;
        final hasHepa = telemetry.hasHepaData;
        
        if (!hasAqi && !hasHepa) return const SizedBox.shrink();

        return Column(
          children: [
            // PM Readings - Full width row with all values
            if (hasAqi) ...[
              _PmReadingsRow(
                telemetry: telemetry,
                onTap: () => _showAqiDetails(context, telemetry),
              ),
              const SizedBox(height: 12),
            ],
            // HEPA Status - Expandable box below
            if (hasHepa) ...[
              _ExpandableHepaBox(
                telemetry: telemetry,
                onTap: () => _showHepaDetails(context, telemetry),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  void _showAqiDetails(BuildContext context, AhuTelemetry telemetry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AqiDetailsSheet(telemetry: telemetry),
    );
  }

  void _showHepaDetails(BuildContext context, AhuTelemetry telemetry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HepaDetailsSheet(telemetry: telemetry),
    );
  }
}

/// Full-width PM readings row - shows PM1.0, PM2.5, PM4.0, PM10, VOC, NOx, CO2
class _PmReadingsRow extends StatelessWidget {
  final AhuTelemetry telemetry;
  final VoidCallback onTap;

  const _PmReadingsRow({required this.telemetry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final aqiColor = Color(telemetry.aqiColorValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with AQI badge
              Row(
                children: [
                  Icon(Icons.air_rounded, color: aqiColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Air Quality',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  // AQI Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: aqiColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: aqiColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AQI ${telemetry.aqi ?? '--'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: aqiColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          telemetry.aqiCategory,
                          style: TextStyle(fontSize: 10, color: aqiColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 14),
              // PM Values - Large display
              Row(
                children: [
                  _PmValueCard(
                    label: 'PM1.0',
                    value: telemetry.pm1p0?.toStringAsFixed(0) ?? '--',
                    unit: 'µg/m³',
                    color: const Color(0xFF4CAF50),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _PmValueCard(
                    label: 'PM2.5',
                    value: telemetry.pm2p5?.toStringAsFixed(0) ?? '--',
                    unit: 'µg/m³',
                    color: const Color(0xFFFF9800),
                    isDark: isDark,
                    isHighlight: true, // PM2.5 is key metric
                  ),
                  const SizedBox(width: 8),
                  _PmValueCard(
                    label: 'PM4.0',
                    value: telemetry.pm4p0?.toStringAsFixed(0) ?? '--',
                    unit: 'µg/m³',
                    color: const Color(0xFF2196F3),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _PmValueCard(
                    label: 'PM10',
                    value: telemetry.pm10p0?.toStringAsFixed(0) ?? '--',
                    unit: 'µg/m³',
                    color: const Color(0xFF9C27B0),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // VOC, NOx, CO2 row - same size as PM values
              Row(
                children: [
                  _PmValueCard(
                    label: 'VOC',
                    value: '${telemetry.voc ?? '--'}',
                    unit: 'index',
                    color: const Color(0xFF00BCD4),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _PmValueCard(
                    label: 'NOx',
                    value: '${telemetry.nox ?? '--'}',
                    unit: 'index',
                    color: const Color(0xFFE91E63),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _PmValueCard(
                    label: 'CO₂',
                    value: '${telemetry.co2 ?? '--'}',
                    unit: 'ppm',
                    color: const Color(0xFF607D8B),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PM value card with large number
class _PmValueCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;
  final bool isHighlight;

  const _PmValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isHighlight ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: isHighlight 
              ? Border.all(color: color.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isHighlight ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 8,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Expandable HEPA status box
class _ExpandableHepaBox extends StatelessWidget {
  final AhuTelemetry telemetry;
  final VoidCallback onTap;

  const _ExpandableHepaBox({required this.telemetry, required this.onTap});

  Color _getHepaColor() {
    final status = telemetry.calculatedHepaStatus;
    if (status.contains('Normal')) return const Color(0xFF4CAF50);
    if (status.contains('Clogging')) return const Color(0xFFFF9800);
    if (status.contains('Replace')) return const Color(0xFFF44336);
    if (status.contains('Fan Off')) return const Color(0xFF9E9E9E);
    return const Color(0xFFF44336);
  }

  IconData _getHepaIcon() {
    final status = telemetry.calculatedHepaStatus;
    if (status.contains('Normal')) return Icons.check_circle_rounded;
    if (status.contains('Clogging')) return Icons.warning_rounded;
    if (status.contains('Fan Off')) return Icons.power_off_rounded;
    return Icons.error_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hepaColor = _getHepaColor();
    final health = telemetry.calculatedHepaHealth;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hepaColor.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              // HEPA Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [hepaColor, hepaColor.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(color: hepaColor.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: Icon(_getHepaIcon(), color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              // HEPA Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'HEPA Filter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: hepaColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            telemetry.calculatedHepaStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hepaColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Health bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: health / 100,
                              minHeight: 8,
                              backgroundColor: isDark ? Colors.white12 : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(hepaColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$health%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: hepaColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ΔP: ${telemetry.diffPressure?.toStringAsFixed(1) ?? '--'} Pa',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: hepaColor.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}


/// Full AQI details bottom sheet
class _AqiDetailsSheet extends StatelessWidget {
  final AhuTelemetry telemetry;

  const _AqiDetailsSheet({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final aqi = telemetry.aqi ?? 0;
    final aqiColor = Color(telemetry.aqiColorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 450),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Big AQI display
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [aqiColor, aqiColor.withOpacity(0.7)]),
                      boxShadow: [BoxShadow(color: aqiColor.withOpacity(0.4), blurRadius: 20)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$aqi', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('AQI', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(telemetry.aqiCategory, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: aqiColor)),
                  const SizedBox(height: 20),
                  // PM Values
                  Row(
                    children: [
                      _DetailCard(label: 'PM1.0', value: '${telemetry.pm1p0?.toStringAsFixed(1) ?? '--'}', unit: 'µg/m³', color: const Color(0xFF4CAF50)),
                      const SizedBox(width: 8),
                      _DetailCard(label: 'PM2.5', value: '${telemetry.pm2p5?.toStringAsFixed(1) ?? '--'}', unit: 'µg/m³', color: const Color(0xFFFF9800)),
                      const SizedBox(width: 8),
                      _DetailCard(label: 'PM4.0', value: '${telemetry.pm4p0?.toStringAsFixed(1) ?? '--'}', unit: 'µg/m³', color: const Color(0xFF2196F3)),
                      const SizedBox(width: 8),
                      _DetailCard(label: 'PM10', value: '${telemetry.pm10p0?.toStringAsFixed(1) ?? '--'}', unit: 'µg/m³', color: const Color(0xFF9C27B0)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Gas values
                  Row(
                    children: [
                      Expanded(child: _DetailCard(label: 'CO₂', value: '${telemetry.co2 ?? '--'}', unit: 'ppm', color: Colors.teal)),
                      const SizedBox(width: 8),
                      Expanded(child: _DetailCard(label: 'VOC', value: '${telemetry.voc?.toStringAsFixed(0) ?? '--'}', unit: 'index', color: const Color(0xFF00BCD4))),
                      const SizedBox(width: 8),
                      Expanded(child: _DetailCard(label: 'NOx', value: '${telemetry.nox?.toStringAsFixed(0) ?? '--'}', unit: 'index', color: const Color(0xFF795548))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full HEPA details bottom sheet
class _HepaDetailsSheet extends StatelessWidget {
  final AhuTelemetry telemetry;

  const _HepaDetailsSheet({required this.telemetry});

  Color _getHepaColor() {
    final status = telemetry.calculatedHepaStatus;
    if (status.contains('Normal')) return const Color(0xFF4CAF50);
    if (status.contains('Clogging')) return const Color(0xFFFF9800);
    if (status.contains('Replace')) return const Color(0xFFF44336);
    if (status.contains('Fan Off')) return const Color(0xFF9E9E9E);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final hepaColor = _getHepaColor();
    final health = telemetry.calculatedHepaHealth;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // HEPA Status Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [hepaColor, hepaColor.withOpacity(0.7)]),
                    boxShadow: [BoxShadow(color: hepaColor.withOpacity(0.4), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.filter_alt_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(telemetry.calculatedHepaStatus, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: hepaColor)),
                const SizedBox(height: 20),
                // Health bar
                Row(
                  children: [
                    Text('Health:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: health / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [hepaColor, hepaColor.withOpacity(0.7)]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$health%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: hepaColor)),
                  ],
                ),
                const SizedBox(height: 20),
                // Pressure reading
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.speed_rounded, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Text('Differential Pressure: ', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                      Text('${telemetry.diffPressure?.toStringAsFixed(2) ?? '--'} Pa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                // Fan Speed Dependent Ranges
                Column(
                  children: [
                    Text('Normal Ranges by Fan Speed:', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HepaBadge(label: 'Low', status: '40-55Pa', color: const Color(0xFF4CAF50)),
                        _HepaBadge(label: 'Mid', status: '60-90Pa', color: const Color(0xFF4CAF50)),
                        _HepaBadge(label: 'High', status: '90-110Pa', color: const Color(0xFF4CAF50)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _DetailCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(unit, style: TextStyle(fontSize: 8, color: isDark ? Colors.white54 : Colors.black38)),
          ],
        ),
      ),
    );
  }
}

class _HepaBadge extends StatelessWidget {
  final String label;
  final String status;
  final Color color;

  const _HepaBadge({required this.label, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}


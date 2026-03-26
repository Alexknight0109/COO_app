import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../models/ahu_unit.dart';
import '../models/ahu_telemetry.dart';
import '../models/ahu_state.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'ahu_control_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

/// Modern dashboard with centered AHU cards
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                : [
                    Colors.white,
                    Colors.blue.shade50,
                    Colors.blue.shade100,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _DashboardTopBar(isDark: isDark),
              // AHU Cards
              Expanded(
                child: _AhuCardsList(isDark: isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Exit functionality moved to Admin screen only

class _DashboardTopBar extends StatelessWidget {
  final bool isDark;
  
  const _DashboardTopBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 650; // Pi display is 600px height
    
    // Compact padding for 7-inch Pi display (1024x600)
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16, 
        vertical: isSmallScreen ? 6 : 12,
      ),
      child: Row(
        children: [
          // ALMED Branding
          Text(
            'ALMED',
            style: TextStyle(
              fontFamily: 'Verdana',
              fontSize: isSmallScreen ? 18 : 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 20),
          Container(
            width: 1,
            height: isSmallScreen ? 22 : 30,
            color: theme.dividerColor.withOpacity(0.3),
          ),
          SizedBox(width: isSmallScreen ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dashboard',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: isSmallScreen ? 20 : 28,
                  ),
                ),
                if (!isSmallScreen) ...[
                  const SizedBox(height: 4),
                  const _ConnectionStatus(),
                ],
              ],
            ),
          ),
          if (isSmallScreen)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: _ConnectionStatus(),
            ),
          // Action buttons - smaller on Pi
          _ActionButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            isSmall: isSmallScreen,
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          SizedBox(width: isSmallScreen ? 6 : 12),
          _ThemeToggleButton(isSmall: isSmallScreen),
          SizedBox(width: isSmallScreen ? 6 : 12),
          _AdminSettingsButton(isSmall: isSmallScreen),
        ],
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus();

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, bool>(
      selector: (_, provider) => provider.isConnected,
      builder: (context, isConnected, _) {
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isConnected ? AppTheme.success : AppTheme.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Connected' : 'Disconnected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isSmall;
  
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: isSmall ? 18 : 24),
        iconSize: isSmall ? 18 : 24,
        padding: EdgeInsets.all(isSmall ? 6 : 8),
        constraints: BoxConstraints(
          minWidth: isSmall ? 32 : 48,
          minHeight: isSmall ? 32 : 48,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final bool isSmall;
  
  const _ThemeToggleButton({this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, bool>(
      selector: (_, provider) => provider.isDarkMode,
      builder: (context, isDarkMode, _) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.1),
            ),
          ),
          child: IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: isSmall ? 18 : 24,
            ),
            iconSize: isSmall ? 18 : 24,
            padding: EdgeInsets.all(isSmall ? 6 : 8),
            constraints: BoxConstraints(
              minWidth: isSmall ? 32 : 48,
              minHeight: isSmall ? 32 : 48,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        );
      },
    );
  }
}

class _AdminSettingsButton extends StatelessWidget {
  final bool isSmall;
  
  const _AdminSettingsButton({this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, UserRole?>(
      selector: (_, provider) => provider.currentRole,
      builder: (context, role, _) {
        if (role != UserRole.admin) {
          return const SizedBox.shrink();
        }
        
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.1),
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.settings_rounded, size: isSmall ? 18 : 24),
            iconSize: isSmall ? 18 : 24,
            padding: EdgeInsets.all(isSmall ? 6 : 8),
            constraints: BoxConstraints(
              minWidth: isSmall ? 32 : 48,
              minHeight: isSmall ? 32 : 48,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AdminScreen()),
              );
            },
          ),
        );
      },
    );
  }
}

class _AhuCardsList extends StatelessWidget {
  final bool isDark;
  
  const _AhuCardsList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 650;
    
    return Selector<AppProvider, List<AhuUnit>>(
      selector: (_, provider) => provider.visibleAhuUnits,
      builder: (context, ahus, _) {
        if (ahus.isEmpty) {
          return _EmptyState(isDark: isDark);
        }

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 16, 
              vertical: isSmallScreen ? 8 : 16,
            ),
            child: Wrap(
              spacing: isSmallScreen ? 10 : 16,
              runSpacing: isSmallScreen ? 10 : 16,
              alignment: WrapAlignment.center,
              // RPi Performance: Wrap each card in RepaintBoundary
              children: ahus.map((ahu) => RepaintBoundary(
                child: _ModernAhuCard(ahu: ahu, isSmallScreen: isSmallScreen),
              )).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                isDark 
                    ? 'assets/images/logo_light.png'
                    : 'assets/images/logo_dark.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.air_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No AHU units configured',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Data class for AHU card to enable efficient rebuilds
@immutable
class _AhuCardData {
  final AhuTelemetry? telemetry;
  final AhuState? state;
  final String? status;

  const _AhuCardData({
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
  int get hashCode => Object.hash(telemetry, state, status);
}

class _ModernAhuCard extends StatelessWidget {
  final AhuUnit ahu;
  final bool isSmallScreen;

  const _ModernAhuCard({required this.ahu, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, _AhuCardData>(
      selector: (_, provider) => _AhuCardData(
        telemetry: provider.getTelemetry(ahu.id),
        state: provider.getState(ahu.id),
        status: provider.getStatus(ahu.id),
      ),
      builder: (context, data, _) {
        final isOnline = data.status == 'online';
        final isRunning = data.state?.run ?? false;
        final theme = Theme.of(context);

        // Optimized for 7-inch 1024x600 Pi display - fits 2-3 cards
        final cardWidth = isSmallScreen ? 310.0 : 320.0;
        
        return SizedBox(
          width: cardWidth,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AhuControlScreen(ahuId: ahu.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status
                    _CardHeader(ahu: ahu, isOnline: isOnline, isSmallScreen: isSmallScreen),
                    SizedBox(height: isSmallScreen ? 10 : 16),
                    // Sensors
                    _SensorRow(data: data, isSmallScreen: isSmallScreen),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    // Status chips
                    _StatusChips(data: data, isRunning: isRunning, isSmallScreen: isSmallScreen),
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

class _CardHeader extends StatelessWidget {
  final AhuUnit ahu;
  final bool isOnline;
  final bool isSmallScreen;
  
  const _CardHeader({required this.ahu, required this.isOnline, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isOnline ? AppTheme.success : AppTheme.error;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ahu.name,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: isSmallScreen ? 18 : 22,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                '${ahu.room.toUpperCase()} • ${ahu.site}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: isSmallScreen ? 11 : 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12, 
            vertical: isSmallScreen ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSmallScreen ? 5 : 6,
                height: isSmallScreen ? 5 : 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SensorRow extends StatelessWidget {
  final _AhuCardData data;
  final bool isSmallScreen;
  
  const _SensorRow({required this.data, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    // Always show just temp and humidity on the AHU list (hospital page)
    // This keeps the cards clean and consistent for 7-inch Pi display
    return Row(
      children: [
        Expanded(
          child: _SensorDisplay(
            icon: Icons.thermostat_rounded,
            value: data.telemetry?.temp?.toStringAsFixed(1) ?? '--',
            unit: '°C',
            color: AppTheme.temperature,
            isSmallScreen: isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _SensorDisplay(
            icon: Icons.water_drop_rounded,
            value: data.telemetry?.hum?.toStringAsFixed(1) ?? '--',
            unit: '%',
            color: AppTheme.humidity,
            isSmallScreen: isSmallScreen,
          ),
        ),
      ],
    );
  }
}

class _SensorDisplay extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;
  final bool isSmallScreen;

  const _SensorDisplay({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 22 : 28),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 14,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final _AhuCardData data;
  final bool isRunning;
  final bool isSmallScreen;
  
  const _StatusChips({required this.data, required this.isRunning, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: isSmallScreen ? 6 : 8,
      runSpacing: isSmallScreen ? 6 : 8,
      children: [
        _StatusChip(
          label: 'Running',
          isActive: isRunning,
          color: AppTheme.success,
          isSmallScreen: isSmallScreen,
        ),
        _StatusChip(
          label: 'CP',
          isActive: data.state?.cp ?? false,
          color: AppTheme.info,
          isSmallScreen: isSmallScreen,
        ),
        _StatusChip(
          label: 'Heater',
          isActive: data.state?.heater ?? false,
          color: AppTheme.info,
          isSmallScreen: isSmallScreen,
        ),
        _StatusChip(
          label: _getFanLabel(data.state?.fanSpeed ?? 0),
          isActive: data.state?.fan ?? false,
          color: AppTheme.success,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }
  
  String _getFanLabel(int fanSpeed) {
    switch (fanSpeed) {
      case 0: return 'Fan OFF';
      case 1: return 'Fan LOW';
      case 2: return 'Fan MID';
      case 3: return 'Fan HIGH';
      default: return 'Fan';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final bool isSmallScreen;

  const _StatusChip({
    required this.label,
    required this.isActive,
    required this.color,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12, 
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 10),
        border: Border.all(
          color: isActive ? color : theme.dividerColor.withOpacity(0.3),
          width: isSmallScreen ? 1 : 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: isActive ? color : theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}

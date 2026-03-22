import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/ahu_telemetry.dart';
import '../theme/app_theme.dart';

/// Display widget for air quality data from SEN66 + SDP810 combo sensors
class AirQualityDisplay extends StatelessWidget {
  final AhuTelemetry? telemetry;

  const AirQualityDisplay({super.key, this.telemetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (telemetry == null || !telemetry!.hasAirQualityData) {
      return const SizedBox.shrink();
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _SectionHeader(
                  icon: Icons.air_rounded,
                  title: 'Air Quality',
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                // AQI Big Display
                _AqiDisplay(telemetry: telemetry!),
                const SizedBox(height: 20),
                // PM Values Grid
                _PmGrid(telemetry: telemetry!),
                const SizedBox(height: 16),
                // Gas Indices Row
                _GasIndicesRow(telemetry: telemetry!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.info.withOpacity(0.2), AppTheme.info.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppTheme.info),
        ),
        const SizedBox(width: 12),
        Text(
          title,
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

class _AqiDisplay extends StatelessWidget {
  final AhuTelemetry telemetry;

  const _AqiDisplay({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final aqi = telemetry.aqi ?? 0;
    final aqiColor = Color(telemetry.aqiColorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [aqiColor.withOpacity(0.15), aqiColor.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: aqiColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // AQI Circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [aqiColor, aqiColor.withOpacity(0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: aqiColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$aqi',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'AQI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // AQI Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  telemetry.aqiCategory,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: aqiColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Air Quality Index',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                // CO2 badge
                if (telemetry.co2 != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.co2, size: 18, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(
                          '${telemetry.co2} ppm',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          telemetry.co2Level,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PmGrid extends StatelessWidget {
  final AhuTelemetry telemetry;

  const _PmGrid({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PmCard(
            label: 'PM1.0',
            value: telemetry.pm1p0,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PmCard(
            label: 'PM2.5',
            value: telemetry.pm2p5,
            color: const Color(0xFFFF9800),
            isHighlighted: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PmCard(
            label: 'PM4.0',
            value: telemetry.pm4p0,
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PmCard(
            label: 'PM10',
            value: telemetry.pm10p0,
            color: const Color(0xFF9C27B0),
          ),
        ),
      ],
    );
  }
}

class _PmCard extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  final bool isHighlighted;

  const _PmCard({
    required this.label,
    required this.value,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHighlighted
              ? [color.withOpacity(0.2), color.withOpacity(0.1)]
              : [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(isHighlighted ? 0.4 : 0.2),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value?.toStringAsFixed(1) ?? '--',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'µg/m³',
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _GasIndicesRow extends StatelessWidget {
  final AhuTelemetry telemetry;

  const _GasIndicesRow({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GasCard(
            icon: Icons.science_rounded,
            label: 'VOC Index',
            value: telemetry.voc?.toStringAsFixed(0) ?? '--',
            color: const Color(0xFF00BCD4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GasCard(
            icon: Icons.cloud_rounded,
            label: 'NOx Index',
            value: telemetry.nox?.toStringAsFixed(0) ?? '--',
            color: const Color(0xFF795548),
          ),
        ),
      ],
    );
  }
}

class _GasCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GasCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Display widget for HEPA filter status from SDP810
class HepaStatusDisplay extends StatelessWidget {
  final AhuTelemetry? telemetry;

  const HepaStatusDisplay({super.key, this.telemetry});

  Color _getHepaColor() {
    final status = telemetry?.calculatedHepaStatus ?? '';
    if (status.contains('Normal')) return const Color(0xFF4CAF50);
    if (status.contains('Clogging')) return const Color(0xFFFF9800);
    if (status.contains('Replace')) return const Color(0xFFF44336);
    if (status.contains('Leak') || status.contains('Weak')) return const Color(0xFFF44336);
    if (status.contains('Fan Off')) return const Color(0xFF9E9E9E);
    return Colors.grey;
  }
  
  IconData _getHepaIcon() {
    final status = telemetry?.calculatedHepaStatus ?? '';
    if (status.contains('Normal')) return Icons.check_circle_rounded;
    if (status.contains('Clogging')) return Icons.warning_rounded;
    if (status.contains('Replace')) return Icons.error_rounded;
    if (status.contains('Leak') || status.contains('Weak')) return Icons.air_rounded;
    if (status.contains('Fan Off')) return Icons.power_off_rounded;
    return Icons.filter_alt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (telemetry == null || !telemetry!.hasHepaData) {
      return const SizedBox.shrink();
    }

    final hepaColor = _getHepaColor();
    final health = telemetry!.calculatedHepaHealth;

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [hepaColor.withOpacity(0.2), hepaColor.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.filter_alt_rounded, size: 20, color: hepaColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'HEPA Filter Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Status and Health
                Row(
                  children: [
                    // Status Icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [hepaColor, hepaColor.withOpacity(0.7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: hepaColor.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getHepaIcon(),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Status Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            telemetry!.calculatedHepaStatus,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: hepaColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ΔP: ${telemetry!.diffPressure?.toStringAsFixed(2) ?? '--'} Pa',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Health Percentage
                    Column(
                      children: [
                        Text(
                          '$health%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: hepaColor,
                          ),
                        ),
                        Text(
                          'Health',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Health Bar
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: health / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [hepaColor, hepaColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HepaLegend(label: 'Low', status: '40-55Pa', color: const Color(0xFF4CAF50)),
                    _HepaLegend(label: 'Mid', status: '60-90Pa', color: const Color(0xFF4CAF50)),
                    _HepaLegend(label: 'High', status: '90-110Pa', color: const Color(0xFF4CAF50)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HepaLegend extends StatelessWidget {
  final String label;
  final String status;
  final Color color;

  const _HepaLegend({
    required this.label,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}


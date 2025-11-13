import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class StatCard extends StatelessWidget {
  final StatCardData data;

  const StatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data.color.withOpacity(0.1),
              data.color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.label,
                  style: theme.textTheme.bodyMedium,
                ),
                Icon(
                  data.icon,
                  color: data.color,
                  size: 28,
                ),
              ],
            ),
            Text(
              data.value,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .scale(delay: 100.ms, duration: 300.ms, curve: Curves.easeOut)
        .shimmer(delay: 200.ms, duration: 1000.ms);
  }
}

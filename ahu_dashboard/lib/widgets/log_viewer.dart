import 'package:flutter/material.dart';
import '../models/ahu_log.dart';

/// Widget to display system logs - optimized for RPi
class LogViewer extends StatelessWidget {
  final List<AhuLog> logs;
  
  // Display all stored logs (max 70 in memory)
  static const int _maxDisplayedLogs = 70;

  const LogViewer({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // RPi Performance: Only show last 50 logs
    final displayLogs = logs.length > _maxDisplayedLogs 
        ? logs.sublist(logs.length - _maxDisplayedLogs) 
        : logs;
    
    return Card(
      elevation: 2, // RPi: Reduced elevation for performance
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'System Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${displayLogs.length}/${logs.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 250, // RPi: Reduced height
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: displayLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      reverse: true, // Show newest first
                      padding: const EdgeInsets.all(8),
                      itemCount: displayLogs.length,
                      // RPi Performance: Limit cache extent
                      cacheExtent: 100,
                      // RPi Performance: Add key for efficient rebuilds
                      itemBuilder: (context, index) {
                        final log = displayLogs[displayLogs.length - 1 - index];
                        return RepaintBoundary(
                          child: _LogEntry(log: log, isDark: isDark),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Separate widget for log entry - optimized for RPi
class _LogEntry extends StatelessWidget {
  final AhuLog log;
  final bool isDark;
  
  const _LogEntry({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(log.lvl);
    final levelIcon = _getLevelIcon(log.lvl);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(levelIcon, size: 14, color: levelColor),
          const SizedBox(width: 6),
          Text(
            log.formattedTime,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              log.msg,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  static Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR': return Colors.red;
      case 'WARN': return Colors.orange;
      default: return Colors.blue;
    }
  }
  
  static IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR': return Icons.error;
      case 'WARN': return Icons.warning;
      default: return Icons.info;
    }
  }
}



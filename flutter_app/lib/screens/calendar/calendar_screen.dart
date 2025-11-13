import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/main_layout.dart';
import '../../theme/app_theme.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month - 3, 1);
    final lastDay = DateTime(now.year, now.month + 3, 31);

    return MainLayout(
      title: 'Calendar',
      subtitle: 'View your schedule and upcoming events',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar View
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TableCalendar(
                        firstDay: firstDay,
                        lastDay: lastDay,
                        focusedDay: now,
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                            ),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: AppTheme.accentPurple.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: AppTheme.accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
            const SizedBox(width: 24),
            // Upcoming Events
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Events',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return _EventItem(index: index)
                                .animate()
                                .fadeIn(duration: 200.ms, delay: (index * 50).ms);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventItem extends StatelessWidget {
  final int index;

  const _EventItem({required this.index});

  static final List<Map<String, String>> events = [
    {'title': 'Team Meeting', 'time': '10:00 AM - 11:00 AM', 'date': '2024-01-15'},
    {'title': 'Site Visit - Project Alpha', 'time': '2:00 PM - 4:00 PM', 'date': '2024-01-16'},
    {'title': 'Deadline: Quotation Review', 'time': 'All Day', 'date': '2024-01-17'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = events[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: AppTheme.accentPurple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event['title']!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text(
                event['time']!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event['date']!,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

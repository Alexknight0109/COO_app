import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/stat_card.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCardData(
        label: 'Active Tasks',
        value: '12',
        icon: Icons.task,
        color: Colors.purple,
      ),
      StatCardData(
        label: 'Unread Messages',
        value: '5',
        icon: Icons.message,
        color: Colors.blue,
      ),
      StatCardData(
        label: 'Upcoming Events',
        value: '8',
        icon: Icons.event,
        color: Colors.green,
      ),
      StatCardData(
        label: 'Completed Tasks',
        value: '24',
        icon: Icons.check_circle,
        color: Colors.orange,
      ),
    ];

    return MainLayout(
      title: 'Dashboard',
      subtitle: 'Welcome back! Here\'s what\'s happening today.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                return StatCard(data: stats[index])
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1, end: 0, duration: 300.ms, delay: (index * 50).ms);
              },
            ),
            
            const SizedBox(height: 32),
            
            // Recent Tasks & Announcements
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Tasks
                Expanded(
                  child: _RecentTasksCard()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .slideX(begin: -0.1, end: 0, duration: 400.ms, delay: 200.ms),
                ),
                const SizedBox(width: 24),
                // Announcements
                Expanded(
                  child: _AnnouncementsCard()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideX(begin: 0.1, end: 0, duration: 400.ms, delay: 300.ms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTasksCard extends StatelessWidget {
  final recentTasks = [
    {
      'title': 'Complete Site Survey',
      'status': 'WORKING',
      'priority': 'HIGH',
      'dueDate': '2024-01-15',
    },
    {
      'title': 'Review Quotation',
      'status': 'REVIEWING',
      'priority': 'MEDIUM',
      'dueDate': '2024-01-14',
    },
    {
      'title': 'Follow up with Client',
      'status': 'NOT_STARTED',
      'priority': 'URGENT',
      'dueDate': '2024-01-13',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Tasks',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...recentTasks.map((task) => _TaskItem(task: task)),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Map<String, String> task;

  const _TaskItem({required this.task});

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task['title']!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task['priority']!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task['priority']!,
                  style: TextStyle(
                    color: _getPriorityColor(task['priority']!),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task['status']!.replaceAll('_', ' ').toLowerCase(),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Due: ${task['dueDate']!}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsCard extends StatelessWidget {
  final announcements = [
    {
      'title': 'New Safety Protocol',
      'message': 'All site workers must attend safety briefing tomorrow at 9 AM.',
      'date': '2024-01-12',
    },
    {
      'title': 'Holiday Schedule',
      'message': 'Factory will be closed next Friday for maintenance.',
      'date': '2024-01-11',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Announcements',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...announcements.map((announcement) => _AnnouncementItem(
              announcement: announcement,
            )),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  final Map<String, String> announcement;

  const _AnnouncementItem({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple.withOpacity(0.1),
            AppTheme.accentBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentPurple.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement['title']!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            announcement['message']!,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            announcement['date']!,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class TaskKanbanColumn extends StatefulWidget {
  final TaskStatus status;
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task)? onTaskMoved;

  const TaskKanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onTaskTap,
    this.onTaskMoved,
  });

  @override
  State<TaskKanbanColumn> createState() => _TaskKanbanColumnState();
}

class _TaskKanbanColumnState extends State<TaskKanbanColumn> {
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks);
  }

  @override
  void didUpdateWidget(TaskKanbanColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _tasks = List.from(widget.tasks);
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Colors.grey;
      case TaskStatus.working:
        return Colors.blue;
      case TaskStatus.blocked:
        return Colors.red;
      case TaskStatus.reviewing:
        return Colors.yellow;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return 'Not Started';
      case TaskStatus.working:
        return 'Working';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.reviewing:
        return 'Reviewing';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusLabel(widget.status),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_tasks.length}',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Draggable<Task>(
                    key: ValueKey(task.id),
                    data: task,
                    feedback: Material(
                      elevation: 6,
                      child: _TaskCard(
                        task: task,
                        onTap: () {},
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _TaskCard(
                        task: task,
                        onTap: () => widget.onTaskTap(task),
                      ),
                    ),
                    child: _TaskCard(
                      task: task,
                      onTap: () => widget.onTaskTap(task),
                    )
                        .animate()
                        .fadeIn(duration: 200.ms, delay: (index * 50).ms)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 200.ms,
                          delay: (index * 50).ms,
                        ),
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

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.priority.name.toUpperCase(),
                        style: TextStyle(
                          color: task.priorityColor,
                          fontSize: 10,
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
                      task.assignee,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (task.dueDate != null)
                      Text(
                        'Due: ${task.dueDate!.day}/${task.dueDate!.month}',
                        style: theme.textTheme.bodySmall,
                      ),
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

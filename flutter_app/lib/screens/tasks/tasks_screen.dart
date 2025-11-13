import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/main_layout.dart';
import '../../models/task_model.dart';
import '../../widgets/task_kanban_column.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<TaskStatus, List<Task>> tasks = {
    TaskStatus.notStarted: [
      Task(
        id: '1',
        title: 'Complete Site Survey',
        priority: TaskPriority.high,
        assignee: 'John Doe',
      ),
      Task(
        id: '2',
        title: 'Review Design Documents',
        priority: TaskPriority.medium,
        assignee: 'Jane Smith',
      ),
    ],
    TaskStatus.working: [
      Task(
        id: '3',
        title: 'Installation Pipeline',
        priority: TaskPriority.urgent,
        assignee: 'Mike Johnson',
      ),
      Task(
        id: '4',
        title: 'Client Follow-up',
        priority: TaskPriority.medium,
        assignee: 'Sarah Williams',
      ),
    ],
    TaskStatus.blocked: [
      Task(
        id: '5',
        title: 'Material Procurement',
        priority: TaskPriority.high,
        assignee: 'Tom Brown',
      ),
    ],
    TaskStatus.reviewing: [
      Task(
        id: '6',
        title: 'Quality Check',
        priority: TaskPriority.medium,
        assignee: 'Lisa Anderson',
      ),
    ],
    TaskStatus.completed: [
      Task(
        id: '7',
        title: 'Documentation',
        priority: TaskPriority.low,
        assignee: 'David Lee',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);
      await _apiService.initialize();
      final response = await _apiService.getTasks();
      
      if (response.statusCode == 200) {
        final List<dynamic> tasksData = response.data;
        final Map<TaskStatus, List<Task>> loadedTasks = {
          TaskStatus.notStarted: [],
          TaskStatus.working: [],
          TaskStatus.blocked: [],
          TaskStatus.reviewing: [],
          TaskStatus.completed: [],
        };

        for (var taskData in tasksData) {
          final task = Task(
            id: taskData['id'],
            title: taskData['title'],
            description: taskData['description'],
            status: _parseTaskStatus(taskData['status']),
            priority: _parseTaskPriority(taskData['priority']),
            assignee: taskData['assignee']?['firstName'] ?? 'Unknown',
            dueDate: taskData['dueDate'] != null 
                ? DateTime.parse(taskData['dueDate'])
                : null,
          );
          loadedTasks[task.status]!.add(task);
        }

        setState(() {
          tasks = loadedTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  TaskStatus _parseTaskStatus(String status) {
    switch (status) {
      case 'NOT_STARTED':
        return TaskStatus.notStarted;
      case 'WORKING':
        return TaskStatus.working;
      case 'BLOCKED':
        return TaskStatus.blocked;
      case 'REVIEWING':
        return TaskStatus.reviewing;
      case 'COMPLETED':
        return TaskStatus.completed;
      default:
        return TaskStatus.notStarted;
    }
  }

  TaskPriority _parseTaskPriority(String priority) {
    switch (priority) {
      case 'LOW':
        return TaskPriority.low;
      case 'MEDIUM':
        return TaskPriority.medium;
      case 'HIGH':
        return TaskPriority.high;
      case 'URGENT':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  Future<void> _onTaskMoved(Task task, TaskStatus newStatus) async {
    try {
      await _apiService.updateTaskStatus(task.id, _statusToString(newStatus));
      setState(() {
        // Remove from old status
        for (var status in TaskStatus.values) {
          tasks[status]!.removeWhere((t) => t.id == task.id);
        }
        // Add to new status
        final updatedTask = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          status: newStatus,
          priority: task.priority,
          assignee: task.assignee,
          dueDate: task.dueDate,
        );
        tasks[newStatus]!.add(updatedTask);
      });
    } catch (e) {
      print('Error updating task status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return 'NOT_STARTED';
      case TaskStatus.working:
        return 'WORKING';
      case TaskStatus.blocked:
        return 'BLOCKED';
      case TaskStatus.reviewing:
        return 'REVIEWING';
      case TaskStatus.completed:
        return 'COMPLETED';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        title: 'Task Management',
        subtitle: 'Loading tasks...',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return MainLayout(
      title: 'Task Management',
      subtitle: 'Drag and drop tasks to update their status',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: TaskStatus.values.map((status) {
            return Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              child: TaskKanbanColumn(
                status: status,
                tasks: tasks[status] ?? [],
                onTaskTap: (task) {
                  _showTaskDetails(task);
                },
                onTaskMoved: (task) => _onTaskMoved(task, status),
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(
                  begin: -0.1,
                  end: 0,
                  duration: 300.ms,
                );
          }).toList(),
        ),
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              Text('Description: ${task.description}'),
              const SizedBox(height: 8),
            ],
            Text('Status: ${task.statusLabel}'),
            Text('Priority: ${task.priority.name.toUpperCase()}'),
            Text('Assignee: ${task.assignee}'),
            if (task.dueDate != null)
              Text('Due Date: ${task.dueDate!.toString().split(' ')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

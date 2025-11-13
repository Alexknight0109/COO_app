import 'package:flutter/material.dart';

enum TaskStatus {
  notStarted,
  working,
  blocked,
  reviewing,
  completed,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String assignee;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.notStarted,
    this.priority = TaskPriority.medium,
    required this.assignee,
    this.dueDate,
  });

  String get statusLabel {
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

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.grey;
    }
  }
}

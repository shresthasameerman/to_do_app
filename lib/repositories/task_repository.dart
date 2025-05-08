// repositories/task_repository.dart
import 'package:to_do_app/services/DatabaseService.dart';

class TaskRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<int> addTask({
    required int userId,
    required String title,
    String? description,
    String category = 'Work',
    String priority = 'low',
    DateTime? dueDate,
    DateTime? reminderTime,
  }) async {
    final task = {
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
    };

    final taskId = await _dbService.createTask(task);

    // Schedule notification if reminder time is set
    if (reminderTime != null) {
      await _dbService.scheduleNotification({
        'user_id': userId,
        'title': 'Task Reminder: $title',
        'body': description ?? 'Your task is due soon!',
        'payload': 'task:$taskId',
        'scheduled_time': reminderTime.toIso8601String(),
      });
    }

    return taskId;
  }

  Future<List<Map<String, dynamic>>> getTasks(int userId, {bool? completed}) async {
    return await _dbService.getTasks(userId, completed: completed);
  }

  Future<int> updateTaskCompletion(int taskId, bool isCompleted) async {
    return await _dbService.updateTask(taskId, {
      'is_completed': isCompleted ? 1 : 0,
    });
  }

  Future<int> updateTaskPriority(int taskId, String priority) async {
    return await _dbService.updateTask(taskId, {
      'priority': priority,
    });
  }

  Future<int> updateTaskCategory(int taskId, String category) async {
    return await _dbService.updateTask(taskId, {
      'category': category,
    });
  }

  Future<int> deleteTask(int taskId) async {
    return await _dbService.deleteTask(taskId);
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required int userId,
    required String title,
    required String body,
    required DateTime reminderTime,
  }) async {
    await _dbService.scheduleNotification({
      'user_id': userId,
      'title': title,
      'body': body,
      'payload': 'task:$taskId',
      'scheduled_time': reminderTime.toIso8601String(),
    });
  }
}
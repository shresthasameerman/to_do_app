// services/notification_service.dart
import 'package:to_do_app/services/DatabaseService.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final DatabaseService _dbService = DatabaseService();

  Future<void> initialize() async {
    await _dbService.initializeNotifications();

    // Android-specific setup
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'taskora_channel',
      'Taskora Notifications',
      description: 'Notifications for Taskora app',
      importance: Importance.max,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        _dbService.notifications;

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> checkAndShowNotifications() async {
    await _dbService.checkPendingNotifications();
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

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _dbService.showNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }
}
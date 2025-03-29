import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize notification service
  Future<void> initNotification() async {
    if (_isInitialized) return; // prevent reinitialization
    const initSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  // Request notification permissions (especially for iOS)
  Future<void> requestPermission() async {
    final iosDetails = await notificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosDetails != null) {
      // Handle any specific logic for iOS permissions here if needed
    }
  }

  // Notification Details setup
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminder_channel_id', // Changed channel ID
        'Task Reminders', // Changed channel name
        channelDescription: 'Task Reminder Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // Show Notifications
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }
    return notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
    );
  }
}
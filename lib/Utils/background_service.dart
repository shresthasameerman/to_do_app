import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/Utils/noti_service.dart';
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // For iOS, we need to request permissions
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'taskora_service_channel',
        initialNotificationTitle: 'Taskora Service',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
    );

    await service.startService();
  }

  // iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // Main background service function for both platforms
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    final notiService = NotiService();
    await notiService.initNotification();

    // For Android - required to run as a foreground service
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Load the timer interval from shared preferences
    final prefs = await SharedPreferences.getInstance();
    int reminderIntervalMinutes = prefs.getInt('reminderIntervalMinutes') ?? 5;
    bool isTimerRunning = prefs.getBool('isTimerRunning') ?? false;

    // Only set up the periodic timer if it's enabled
    Timer? periodicTimer;

    void setUpTimer() {
      periodicTimer?.cancel();

      if (isTimerRunning) {
        periodicTimer = Timer.periodic(Duration(minutes: reminderIntervalMinutes), (_) async {
          // Check if timer is still enabled (user might have disabled it)
          final prefs = await SharedPreferences.getInstance();
          bool isStillRunning = prefs.getBool('isTimerRunning') ?? false;

          if (isStillRunning) {
            // Get incomplete tasks count from shared preferences
            int incompleteTasks = prefs.getInt('incompleteTasks') ?? 0;

            if (incompleteTasks > 0) {
              notiService.showNotification(
                title: 'Taskora Reminder',
                body: 'You have $incompleteTasks incomplete tasks',
              );
            }
          }
        });
      }
    }

    // Initial timer setup
    setUpTimer();

    // Listen for updates from the main app
    service.on('update').listen((event) async {
      if (event != null) {
        // Update timer settings
        if (event['reminderIntervalMinutes'] != null) {
          reminderIntervalMinutes = event['reminderIntervalMinutes'];
        }

        if (event['isTimerRunning'] != null) {
          isTimerRunning = event['isTimerRunning'];
        }

        if (event['incompleteTasks'] != null) {
          // Update incomplete tasks count
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('incompleteTasks', event['incompleteTasks']);
        }

        // Reset timer with new settings
        setUpTimer();
      }
    });
  }
}
import 'package:flutter/material.dart';
import 'package:to_do_app/Pages/home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:to_do_app/Utils/noti_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open the box
  await Hive.openBox('mybox');

  // Initialize notifications
  final notiService = NotiService();
  await notiService.initializeNotifications();
  await notiService.requestPermissions(); // Optional: Request permissions if needed

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      theme: ThemeData(primarySwatch: Colors.grey),
    );
  }
}
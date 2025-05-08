import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/Pages/home_page.dart';
import 'package:to_do_app/Pages/login_page.dart';
import 'package:to_do_app/services/DatabaseService.dart';
import 'package:to_do_app/services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('mybox');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _myBox = Hive.box('mybox');
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  void _loadThemePreference() {
    setState(() {
      _isDarkMode = _myBox.get("THEME_MODE", defaultValue: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _myBox.get("IS_LOGGED_IN", defaultValue: false);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taskora',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize database
    final dbService = DatabaseService();
    await dbService.database; // This creates/opens the database

    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.initialize();

    runApp(const MyApp());
  }
}
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskora',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
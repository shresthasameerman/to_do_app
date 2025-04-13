import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/Pages/home_page.dart';
import 'package:to_do_app/Pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('mybox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final myBox = Hive.box('mybox');
    final isLoggedIn = myBox.get("IS_LOGGED_IN") ?? false;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taskora',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Check if user is already logged in
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/Pages/home_page.dart';
import 'package:to_do_app/Pages/signup_page.dart'; // You'll need to create this
import 'dart:io';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _myBox = Hive.box('mybox');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _isLoading = false;

  bool _isDarkMode = true;
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;

  @override
  void initState() {
    super.initState();
    _initThemes();
    _loadThemePreference();
    _checkRememberedUser();
  }

  void _initThemes() {
    // Light theme
    _lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
      ),
    );

    // Dark theme
    _darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
        labelStyle: TextStyle(color: Colors.grey[400]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
      ),
    );
  }

  void _loadThemePreference() {
    _isDarkMode = _myBox.get("THEME_MODE") ?? true;
  }

  void _checkRememberedUser() {
    final rememberedEmail = _myBox.get("REMEMBERED_EMAIL");
    final rememberedPassword = _myBox.get("REMEMBERED_PASSWORD");

    if (rememberedEmail != null && rememberedPassword != null) {
      _emailController.text = rememberedEmail;
      _passwordController.text = rememberedPassword;
      _rememberMe = true;
    }
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar("Please enter email and password");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // In a real app, you would verify credentials against a backend
    // For this demo, we'll use a simple check
    final savedEmail = _myBox.get("USER_EMAIL");
    final savedPassword = _myBox.get("USER_PASSWORD");

    if (savedEmail == _emailController.text && savedPassword == _passwordController.text) {
      // Save credentials if remember me is checked
      if (_rememberMe) {
        _myBox.put("REMEMBERED_EMAIL", _emailController.text);
        _myBox.put("REMEMBERED_PASSWORD", _passwordController.text);
      } else {
        _myBox.delete("REMEMBERED_EMAIL");
        _myBox.delete("REMEMBERED_PASSWORD");
      }

      // Save user as logged in
      _myBox.put("USERNAME", _emailController.text.split('@')[0]); // Use part before @ as username
      _myBox.put("IS_LOGGED_IN", true);

      // Navigate to home page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      if (mounted) {
        _showErrorSnackBar("Invalid email or password");
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  void _forgotPassword() {
    // Show a dialog to get the email for password reset
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your email to receive a password reset link"),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _emailController.text),
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Password reset link sent to your email"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("SEND"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? _darkTheme : _lightTheme,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and App Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Taskora",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your Personal Task Manager",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Form
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to continue",
                    style: TextStyle(
                      fontSize: 16,
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      hintText: "Enter your email",
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      hintText: "Enter your password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 16),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text("Remember Me"),
                        ],
                      ),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text("Forgot Password?"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text("LOG IN"),
                  ),
                  const SizedBox(height: 24),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social Login Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _socialButton(
                        icon: Icons.g_mobiledata,
                        color: Colors.red,
                        onPressed: () {
                          // Implement Google login
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Google login not implemented"),
                            ),
                          );
                        },
                      ),
                      _socialButton(
                        icon: Icons.facebook,
                        color: Colors.blue[800]!,
                        onPressed: () {
                          // Implement Facebook login
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Facebook login not implemented"),
                            ),
                          );
                        },
                      ),
                      _socialButton(
                        icon: Icons.apple,
                        color: _isDarkMode ? Colors.white : Colors.black,
                        onPressed: () {
                          // Implement Apple login
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Apple login not implemented"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToSignUp,
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  // Theme Toggle
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isDarkMode = !_isDarkMode;
                          _myBox.put("THEME_MODE", _isDarkMode);
                        });
                      },
                      icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                      label: Text(_isDarkMode ? "Light Mode" : "Dark Mode"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 32,
        ),
      ),
    );
  }
}
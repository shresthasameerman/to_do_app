import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({Key? key}) : super(key: key);

  @override
  State<StudyTimerPage> createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage> {
  final _myBox = Hive.box('mybox');

  // Timer variables
  Timer? _timer;
  int _secondsRemaining = 25 * 60; // Default 25 minutes for focus
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isBreak = false;

  // Customizable durations (in minutes)
  int _focusDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;

  // Session tracking
  int _completedSessions = 0;
  int _dailyGoal = 4;
  int _sessionsUntilLongBreak = 4;
  int _currentSessionStreak = 0;

  // Stats
  int _totalStudyMinutes = 0;
  int _totalSessionsCompleted = 0;
  List<String> _recentSessions = [];

  // Theme
  bool _isDarkMode = true;

  // Notifications
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadThemePreference();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'pomodoro_timer_channel',
      'Pomodoro Timer',
      channelDescription: 'Notifications for Pomodoro Timer',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _loadData() {
    // Load timer preferences
    final savedFocusDuration = _myBox.get("FOCUS_DURATION");
    final savedShortBreakDuration = _myBox.get("SHORT_BREAK_DURATION");
    final savedLongBreakDuration = _myBox.get("LONG_BREAK_DURATION");
    final savedDailyGoal = _myBox.get("DAILY_GOAL");
    final savedSessionsUntilLongBreak = _myBox.get("SESSIONS_UNTIL_LONG_BREAK");

    // Load statistics
    final savedTotalStudyMinutes = _myBox.get("TOTAL_STUDY_MINUTES");
    final savedTotalSessionsCompleted = _myBox.get("TOTAL_SESSIONS_COMPLETED");
    final savedRecentSessions = _myBox.get("RECENT_SESSIONS");
    final savedCompletedSessions = _myBox.get("COMPLETED_SESSIONS");

    setState(() {
      _focusDuration = savedFocusDuration ?? 25;
      _shortBreakDuration = savedShortBreakDuration ?? 5;
      _longBreakDuration = savedLongBreakDuration ?? 15;
      _dailyGoal = savedDailyGoal ?? 4;
      _sessionsUntilLongBreak = savedSessionsUntilLongBreak ?? 4;

      _totalStudyMinutes = savedTotalStudyMinutes ?? 0;
      _totalSessionsCompleted = savedTotalSessionsCompleted ?? 0;
      _recentSessions = savedRecentSessions != null
          ? List<String>.from(savedRecentSessions)
          : [];
      _completedSessions = savedCompletedSessions ?? 0;

      // Initialize timer with focus duration
      _secondsRemaining = _focusDuration * 60;
    });
  }

  void _loadThemePreference() {
    final savedTheme = _myBox.get("THEME_MODE");
    if (savedTheme != null) {
      setState(() {
        _isDarkMode = savedTheme;
      });
    }
  }

  void _saveData() {
    _myBox.put("FOCUS_DURATION", _focusDuration);
    _myBox.put("SHORT_BREAK_DURATION", _shortBreakDuration);
    _myBox.put("LONG_BREAK_DURATION", _longBreakDuration);
    _myBox.put("DAILY_GOAL", _dailyGoal);
    _myBox.put("SESSIONS_UNTIL_LONG_BREAK", _sessionsUntilLongBreak);

    _myBox.put("TOTAL_STUDY_MINUTES", _totalStudyMinutes);
    _myBox.put("TOTAL_SESSIONS_COMPLETED", _totalSessionsCompleted);
    _myBox.put("RECENT_SESSIONS", _recentSessions);
    _myBox.put("COMPLETED_SESSIONS", _completedSessions);
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();

          // Play sound and show notification
          if (_isBreak) {
            _showNotification("Break Over", "Time to get back to work!");
            _startFocusSession();
          } else {
            // Completed a focus session
            _completeSession();
          }
        }
      },
    );
  }

  void _completeSession() {
    setState(() {
      _completedSessions++;
      _currentSessionStreak++;
      _totalSessionsCompleted++;
      _totalStudyMinutes += _focusDuration;

      // Add to recent sessions
      final now = DateTime.now();
      _recentSessions.insert(0, "${now.day}/${now.month}/${now.year} - $_focusDuration min");
      if (_recentSessions.length > 10) {
        _recentSessions.removeLast();
      }
    });

    _showNotification("Session Complete!", "Great job! Take a break.");

    // Check if it's time for a long break
    if (_currentSessionStreak >= _sessionsUntilLongBreak) {
      _startLongBreak();
    } else {
      _startShortBreak();
    }

    // Save data after session completes
    _saveData();
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _secondsRemaining = _isBreak
          ? (_currentSessionStreak >= _sessionsUntilLongBreak
          ? _longBreakDuration * 60
          : _shortBreakDuration * 60)
          : _focusDuration * 60;
    });
  }

  void _startFocusSession() {
    _timer?.cancel();
    setState(() {
      _isBreak = false;
      _isRunning = false;
      _isPaused = false;
      _secondsRemaining = _focusDuration * 60;
    });
  }

  void _startShortBreak() {
    _timer?.cancel();
    setState(() {
      _isBreak = true;
      _isRunning = false;
      _isPaused = false;
      _secondsRemaining = _shortBreakDuration * 60;
    });
  }

  void _startLongBreak() {
    _timer?.cancel();
    setState(() {
      _isBreak = true;
      _isRunning = false;
      _isPaused = false;
      _secondsRemaining = _longBreakDuration * 60;
      _currentSessionStreak = 0; // Reset streak after long break
    });
  }

  void _skipToNextPhase() {
    if (_isBreak) {
      _startFocusSession();
    } else {
      // If skipping a focus session, don't count it as completed
      if (_currentSessionStreak >= _sessionsUntilLongBreak) {
        _startLongBreak();
      } else {
        _startShortBreak();
      }
    }
  }

  void _showSettingsDialog() {
    // Create controllers with current values
    final focusController = TextEditingController(text: _focusDuration.toString());
    final shortBreakController = TextEditingController(text: _shortBreakDuration.toString());
    final longBreakController = TextEditingController(text: _longBreakDuration.toString());
    final goalController = TextEditingController(text: _dailyGoal.toString());
    final longBreakIntervalController = TextEditingController(text: _sessionsUntilLongBreak.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Timer Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: focusController,
                  decoration: const InputDecoration(labelText: 'Focus Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: shortBreakController,
                  decoration: const InputDecoration(labelText: 'Short Break (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: longBreakController,
                  decoration: const InputDecoration(labelText: 'Long Break (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(labelText: 'Daily Sessions Goal'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: longBreakIntervalController,
                  decoration: const InputDecoration(labelText: 'Sessions Until Long Break'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update values
                setState(() {
                  _focusDuration = int.tryParse(focusController.text) ?? 25;
                  _shortBreakDuration = int.tryParse(shortBreakController.text) ?? 5;
                  _longBreakDuration = int.tryParse(longBreakController.text) ?? 15;
                  _dailyGoal = int.tryParse(goalController.text) ?? 4;
                  _sessionsUntilLongBreak = int.tryParse(longBreakIntervalController.text) ?? 4;

                  // Reset current timer based on current state
                  if (_isBreak) {
                    _secondsRemaining = (_currentSessionStreak >= _sessionsUntilLongBreak
                        ? _longBreakDuration : _shortBreakDuration) * 60;
                  } else {
                    _secondsRemaining = _focusDuration * 60;
                  }
                });

                // Save settings
                _saveData();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    double progress = 1.0;
    if (_isBreak) {
      final totalSeconds = _currentSessionStreak >= _sessionsUntilLongBreak
          ? _longBreakDuration * 60
          : _shortBreakDuration * 60;
      progress = _secondsRemaining / totalSeconds;
    } else {
      progress = _secondsRemaining / (_focusDuration * 60);
    }

    // Ensure progress is between 0 and 1
    progress = progress.clamp(0.0, 1.0);

    // Create theme
    final ThemeData themeData = _isDarkMode
        ? ThemeData.dark().copyWith(
      primaryColor: Colors.blue,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
      ),
      scaffoldBackgroundColor: Colors.grey[900],
    )
        : ThemeData.light().copyWith(
      primaryColor: Colors.blue,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
      ),
    );

    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Timer'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
              tooltip: 'Settings',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: _isBreak ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isBreak ? 'BREAK TIME' : 'FOCUS TIME',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Timer display
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        color: _isBreak ? Colors.green : Colors.blue,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isBreak
                              ? 'Break ends in'
                              : 'Focus time remaining',
                          style: TextStyle(
                            fontSize: 16,
                            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Timer controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(_isRunning ? 'Pause' : _isPaused ? 'Resume' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBreak ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _skipToNextPhase,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Progress stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Today\'s Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(
                            '$_completedSessions/$_dailyGoal',
                            'Sessions',
                            Icons.check_circle,
                          ),
                          _buildStatColumn(
                            '${_focusDuration * _completedSessions}',
                            'Minutes',
                            Icons.timer,
                          ),
                          _buildStatColumn(
                            '${_sessionsUntilLongBreak - _currentSessionStreak}',
                            'Until Long Break',
                            Icons.free_breakfast,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Session progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Goal: $_completedSessions of $_dailyGoal sessions',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _dailyGoal > 0 ? (_completedSessions / _dailyGoal).clamp(0.0, 1.0) : 0,
                            backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            color: Colors.blue,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // All-time stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'All-Time Stats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(
                            '$_totalSessionsCompleted',
                            'Total Sessions',
                            Icons.bar_chart,
                          ),
                          _buildStatColumn(
                            '$_totalStudyMinutes',
                            'Minutes Studied',
                            Icons.access_time,
                          ),
                          _buildStatColumn(
                            '${(_totalStudyMinutes / 60).round()}',
                            'Hours',
                            Icons.hourglass_full,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Recent sessions
                if (_recentSessions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentSessions.length.clamp(0, 5),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.history, size: 16),
                                  const SizedBox(width: 8),
                                  Text(_recentSessions[index]),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String value,
      String label,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
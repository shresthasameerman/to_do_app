import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:to_do_app/Utils/dialog_box.dart';
import 'package:to_do_app/Utils/noti_service.dart';
import 'package:to_do_app/Utils/todo_tile.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final _intervalController = TextEditingController();
  List toDoList = [
    ["watch tutorial", false],
    ["to exercise", false],
  ];

  // Notification service
  final NotiService _notiService = NotiService();
  Timer? _reminderTimer;
  int _reminderIntervalMinutes = 5; // Default interval (in minutes)
  bool _isTimerRunning = false; // Track if timer is active

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startReminderTimer();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _controller.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notiService.initNotification();
  }

  void checkBoxChanged(bool value, int index) {
    setState(() {
      toDoList[index][1] = value;
    });
  }

  Future<void> showTaskNotification(String taskName) async {
    await _notiService.showNotification(
      id: 0,
      title: 'Task Reminder',
      body: 'You have an incomplete task: $taskName',
    );
  }

  Future<void> showAllIncompleteTasks() async {
    List incompleteTasks = toDoList.where((task) => task[1] == false).toList();

    if (incompleteTasks.isEmpty) {
      await _notiService.showNotification(
        id: 1,
        title: 'All Tasks Complete',
        body: 'Great job! You have completed all your tasks.',
      );
    } else {
      String message =
          'You have ${incompleteTasks.length} incomplete ${incompleteTasks.length == 1 ? 'task' : 'tasks'}:\n';
      for (int i = 0; i < incompleteTasks.length && i < 5; i++) {
        message += '• ${incompleteTasks[i][0]}\n';
      }
      if (incompleteTasks.length > 5) {
        message += '• and ${incompleteTasks.length - 5} more...';
      }
      await _notiService.showNotification(
        id: 1,
        title: 'Incomplete Tasks',
        body: message,
      );
    }
  }

  void saveNewTask() {
    setState(() {
      toDoList.add([_controller.text, false]);
      _controller.clear();
    });
    Navigator.of(context).pop();
  }

  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          onSave: saveNewTask,
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void deleteTask(int index) {
    setState(() {
      toDoList.removeAt(index);
    });
  }

  // Start the periodic reminder timer
  void _startReminderTimer() {
    _reminderTimer?.cancel(); // Cancel any existing timer
    _reminderTimer = Timer.periodic(
      Duration(minutes: _reminderIntervalMinutes),
          (timer) => _showPeriodicReminder(),
    );
    setState(() {
      _isTimerRunning = true; // Mark timer as running
    });
  }

  // Stop the timer
  void _stopReminderTimer() {
    _reminderTimer?.cancel();
    setState(() {
      _isTimerRunning = false; // Mark timer as stopped
    });
  }

  Future<void> _showPeriodicReminder() async {
    List incompleteTasks = toDoList.where((task) => task[1] == false).toList();

    if (incompleteTasks.isNotEmpty) {
      String message = 'Reminder: You have incomplete tasks!\n';
      for (int i = 0; i < incompleteTasks.length && i < 5; i++) {
        message += '• ${incompleteTasks[i][0]}\n';
      }
      if (incompleteTasks.length > 5) {
        message += '• and ${incompleteTasks.length - 5} more...';
      }
      await _notiService.showNotification(
        id: 2,
        title: 'Task Reminder',
        body: message,
      );
    }
  }

  // Show dialog to set reminder interval
  void _setReminderInterval() {
    if (_isTimerRunning) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Timer Running'),
            content: const Text(
                'The reminder timer is currently active. Stop it first to set a new interval.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _stopReminderTimer();
                  Navigator.of(context).pop();
                  _setReminderInterval(); // Reopen the set interval dialog
                },
                child: const Text('Stop Timer'),
              ),
            ],
          );
        },
      );
    } else {
      int selectedInterval = _reminderIntervalMinutes;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Set Reminder Interval'),
            content: SizedBox(
              height: 200,
              child: CupertinoPicker(
                itemExtent: 50,
                onSelectedItemChanged: (int index) {
                  selectedInterval = [1, 5, 10, 15, 30, 60][index];
                },
                children: [
                  const Center(child: Text('1 min')),
                  const Center(child: Text('5 mins')),
                  const Center(child: Text('10 mins')),
                  const Center(child: Text('15 mins')),
                  const Center(child: Text('30 mins')),
                  const Center(child: Text('60 mins')),
                ],
                // Set initial selection based on current interval
                scrollController: FixedExtentScrollController(
                  initialItem: [1, 5, 10, 15, 30, 60].indexOf(_reminderIntervalMinutes),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _reminderIntervalMinutes = selectedInterval;
                  });
                  _startReminderTimer(); // Start timer with new interval
                  Navigator.of(context).pop();
                },
                child: const Text('Start Timer'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Taskora'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: showAllIncompleteTasks,
            tooltip: 'Show incomplete tasks',
          ),
          IconButton(
            icon: Icon(
              _isTimerRunning ? Icons.timer : Icons.timer_off,
              color: _isTimerRunning ? Colors.green : Colors.grey,
            ),
            onPressed: _setReminderInterval,
            tooltip: _isTimerRunning
                ? 'Timer Running (every $_reminderIntervalMinutes min)'
                : 'Set reminder interval',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_isTimerRunning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Reminder active: Every $_reminderIntervalMinutes minute${_reminderIntervalMinutes == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.green),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: toDoList.length,
              itemBuilder: (context, index) {
                return ToDoTile(
                  taskName: toDoList[index][0],
                  taskCompleted: toDoList[index][1],
                  onChanged: (value) => checkBoxChanged(value ?? false, index),
                  deleteFunction: (context) => deleteTask(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
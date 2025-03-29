import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:to_do_app/Utils/dialog_box.dart';
import 'package:to_do_app/Utils/noti_service.dart';
import 'package:to_do_app/Utils/todo_tile.dart';
import 'dart:async';

// Priority Enum
enum Priority {
  low(color: Colors.green),
  medium(color: Colors.orange),
  high(color: Colors.red);

  final Color color;
  const Priority({required this.color});

  // Convert to string representation
  String get displayName => name.capitalize();
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  String _selectedCategory = 'Work'; // Default category
  Priority _selectedPriority = Priority.low; // Default priority

  // Updated task structure to include category and priority
  List toDoList = [
    ["watch tutorial", false, "Study", "low"],
    ["to exercise", false, "Health/Exercise", "medium"],
  ];

  // Predefined categories
  final List<String> categories = [
    'Work',
    'Study',
    'Personal',
    'Health/Exercise'
  ];

  // Predefined priorities
  final List<Priority> priorities = Priority.values;

  // Notification and timer variables
  final NotiService _notiService = NotiService();
  Timer? _reminderTimer;
  int _reminderIntervalMinutes = 5;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNotificationPrompt();
    });
  }

  // Method to show the notification prompt
  void _showNotificationPrompt() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enable Notifications"),
          content: const Text(
              "To get timely reminders, please enable notification services."),
          actions: [
            TextButton(
              onPressed: () {
                _notiService.requestPermission();
                Navigator.of(context).pop();
              },
              child: const Text("Enable"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Method to set reminder interval
  void _setReminderInterval() {
    final List<int> reminderIntervals = [1, 5, 10, 15, 30, 60, 120, 180];
    int selectedInterval = _reminderIntervalMinutes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isTimerRunning
              ? 'Reminder Interval'
              : 'Set Reminder Interval'),
          content: SizedBox(
            height: 200,
            child: CupertinoPicker(
              itemExtent: 32.0,
              scrollController: FixedExtentScrollController(
                  initialItem: reminderIntervals.indexOf(selectedInterval)
              ),
              onSelectedItemChanged: (int index) {
                selectedInterval = reminderIntervals[index];
              },
              children: reminderIntervals.map((interval) {
                return Center(
                  child: Text(
                    interval < 60
                        ? '$interval min'
                        : '${interval ~/ 60} hr${interval ~/ 60 == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                if (!_isTimerRunning) {
                  setState(() {
                    _reminderIntervalMinutes = selectedInterval;
                    _isTimerRunning = true;
                  });

                  _reminderTimer = Timer.periodic(
                      Duration(minutes: _reminderIntervalMinutes),
                          (_) {
                        _notiService.showNotification(
                            title: 'Taskora Reminder',
                            body: 'You have ${toDoList.where((task) => task[1] == false).length} incomplete tasks'
                        );
                      }
                  );
                } else {
                  setState(() {
                    _isTimerRunning = false;
                    _reminderTimer?.cancel();
                  });
                }
              },
              child: Text(_isTimerRunning ? 'Stop' : 'Start'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void checkBoxChanged(bool value, int index) {
    setState(() {
      toDoList[index][1] = value;
    });
  }

  void saveNewTask() {
    setState(() {
      toDoList.add([
        _controller.text,
        false,
        _selectedCategory,
        _selectedPriority.name
      ]);
      _controller.clear();
    });
    Navigator.of(context).pop();
  }

  void createNewTask() {
    // Reset selected priority to default
    _selectedPriority = Priority.low;

    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          onSave: saveNewTask,
          onCancel: () => Navigator.of(context).pop(),
          categories: categories,
          selectedCategory: _selectedCategory,
          onCategoryChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue!;
            });
          },
          // Add priority selection
          priorities: priorities.map((p) => p.name).toList(),
          selectedPriority: _selectedPriority.name,
          onPriorityChanged: (String? newValue) {
            setState(() {
              _selectedPriority = Priority.values.firstWhere(
                    (p) => p.name == newValue,
                orElse: () => Priority.low,
              );
            });
          },
        );
      },
    );
  }

  void deleteTask(int index) {
    setState(() {
      toDoList.removeAt(index);
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sort tasks within each category by priority and completion
    Map<String, List> categorizedTasks = {};
    for (var category in categories) {
      List categoryTasks = toDoList.where((task) => task[2] == category).toList();

      // Sort tasks: uncompleted high priority first, then medium, then low
      categoryTasks.sort((a, b) {
        // Define priority order
        Map<String, int> priorityOrder = {
          'high': 0,
          'medium': 1,
          'low': 2
        };

        // First, sort by completion status (incomplete first)
        if (a[1] != b[1]) {
          return a[1] ? 1 : -1;
        }

        // Then sort by priority
        return priorityOrder[a[3]]!.compareTo(priorityOrder[b[3]]!);
      });

      categorizedTasks[category] = categoryTasks;
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Taskora'),
        elevation: 0,
        actions: [
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
            child: DefaultTabController(
              length: categories.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: categories.map((category) => Tab(text: category)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: categories.map((category) {
                        List categoryTasks = categorizedTasks[category]!;
                        return ListView.builder(
                          itemCount: categoryTasks.length,
                          itemBuilder: (context, index) {
                            return ToDoTile(
                              taskName: categoryTasks[index][0],
                              taskCompleted: categoryTasks[index][1],
                              priorityColor: Priority.values.firstWhere(
                                    (p) => p.name == categoryTasks[index][3],
                                orElse: () => Priority.low,
                              ).color,
                              onChanged: (value) {
                                int originalIndex = toDoList.indexOf(categoryTasks[index]);
                                checkBoxChanged(value ?? false, originalIndex);
                              },
                              deleteFunction: (context) {
                                int originalIndex = toDoList.indexOf(categoryTasks[index]);
                                deleteTask(originalIndex);
                              },
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
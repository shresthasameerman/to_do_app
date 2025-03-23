import 'package:flutter/material.dart';
import 'package:to_do_app/Utils/dialog_box.dart';
import 'package:to_do_app/Utils/noti_service.dart';
import 'package:to_do_app/Utils/todo_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  List toDoList = [
    ["watch tutorial", false],
    ["to exercise", false],
  ];

  // Notification service
  final NotiService _notiService = NotiService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notiService.initNotification();
  }

  void checkBoxChanged(bool value, int index) {
    setState(() {
      toDoList[index][1] = value;
    });

    // Optionally notify when a task is marked as incomplete
    if (!value) {
      showTaskNotification(toDoList[index][0]);
    }
  }

  // Show notification for a specific incomplete task
  Future<void> showTaskNotification(String taskName) async {
    await _notiService.showNotification(
      id: 0,
      title: 'Task Reminder',
      body: 'You have an incomplete task: $taskName',
    );
  }

  // Show all incomplete tasks in a single notification
  Future<void> showAllIncompleteTasks() async {
    // Filter out incomplete tasks
    List incompleteTasks = toDoList.where((task) => task[1] == false).toList();

    if (incompleteTasks.isEmpty) {
      // Optional: Show a notification when all tasks are complete
      await _notiService.showNotification(
        id: 1,
        title: 'All Tasks Complete',
        body: 'Great job! You have completed all your tasks.',
      );
    } else {
      // Create a message with all incomplete tasks
      String message = 'You have ${incompleteTasks.length} incomplete ${incompleteTasks.length == 1 ? 'task' : 'tasks'}:\n';

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

  // save new task
  void saveNewTask() {
    setState(() {
      toDoList.add([_controller.text, false]);
      _controller.clear();
    });
    Navigator.of(context).pop();
  }

  // create a new task for save and cancel
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

  // delete task
  void deleteTask(int index) {
    setState(() {
      toDoList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Taskora'),
        elevation: 0,
        actions: [
          // Button to show all incomplete tasks in notification
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: showAllIncompleteTasks,
            tooltip: 'Show incomplete tasks',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
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
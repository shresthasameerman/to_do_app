import 'package:flutter/material.dart';
import 'package:to_do_app/Utils/dialog_box.dart';
import 'package:to_do_app/Utils/noti_service.dart';
import 'package:to_do_app/Utils/todo_tile.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:to_do_app/main.dart';

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

  void checkBoxChanged(bool value, int index) {
    setState(() {
      toDoList[index][1] = !toDoList[index][1];
    });
    if (!value) {
      scheduleNotification(toDoList[index][0]);
    }
  }

  Future<void> scheduleNotification(String taskName) async {
    await NotiService().showNotification(
      id: 0,
      title: 'Incomplete Task',
      body: 'You have an incomplete task: $taskName',
    );
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
  void DeleteTask(int index) {
    setState(() {
      toDoList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Taskora'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        child: Icon(Icons.add),
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
                  deleteFunction: (context) => DeleteTask(index),
                );
              },
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                NotiService().showNotification(
                  title: "Title",
                  body: "Body",
                );
              },
              child: const Text("Send Notification"),
            ),
          ),
        ],
      ),
    );
  }
}
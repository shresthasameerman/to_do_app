import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

// Add Priority Enum
enum Priority {
  low(color: Colors.green),
  medium(color: Colors.orange),
  high(color: Colors.red);

  final Color color;
  const Priority({required this.color});

  // Convert to/from string for Hive storage
  static Priority fromString(String priorityString) {
    return Priority.values.firstWhere(
            (priority) => priority.name == priorityString,
        orElse: () => Priority.low
    );
  }
}

class ToDoDatabase {
  // Update toDoList to include priority
  List toDoList = [];

  // Reference our box
  final _myBox = Hive.box('mybox');

  // 1st time ever user - update initial data to include priority
  void createInitialData() {
    toDoList = [
      ["Make tutorials", false, "low"],
      ["Do Exercise", false, "medium"]
    ];
  }

  // Load the data from database
  void loadData() {
    // Retrieve existing data and ensure compatibility
    var storedList = _myBox.get("TODOLIST");

    if (storedList != null) {
      // Convert existing data to new format if needed
      toDoList = storedList.map<List>((item) {
        // If item doesn't have priority, add default
        if (item is List && item.length == 2) {
          return [...item, "low"];
        }
        // If item already has 3 elements, return as is
        return item;
      }).toList();
    }
  }

  // Update the database
  void updateDataBase() {
    _myBox.put("TODOLIST", toDoList);
  }

  // Helper methods for priority management
  void addToDo(String task, {bool isCompleted = false, Priority priority = Priority.low}) {
    toDoList.add([
      task,
      isCompleted,
      priority.name
    ]);
    updateDataBase();
  }

  void updateTodoPriority(int index, Priority newPriority) {
    if (index >= 0 && index < toDoList.length) {
      toDoList[index][2] = newPriority.name;
      updateDataBase();
    }
  }

  // Get todos sorted by priority
  List getSortedTodos() {
    List sortedList = List.from(toDoList);

    // Custom sorting based on priority and completion
    sortedList.sort((a, b) {
      // Define priority order
      Map<String, int> priorityOrder = {
        'high': 0,
        'medium': 1,
        'low': 2
      };

      // First, sort by priority
      int priorityComparison = priorityOrder[a[2] ?? 'low']!
          .compareTo(priorityOrder[b[2] ?? 'low']!);

      if (priorityComparison != 0) return priorityComparison;

      // Then, sort by completion status (incomplete first)
      return a[1] == b[1] ? 0 : (a[1] ? 1 : -1);
    });

    return sortedList;
  }

  // Get priority color for a specific todo
  Color getPriorityColor(int index) {
    if (index >= 0 && index < toDoList.length) {
      String priorityName = toDoList[index][2] ?? 'low';
      return Priority.fromString(priorityName).color;
    }
    return Priority.low.color;
  }
}
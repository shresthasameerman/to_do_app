import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

enum Priority {
  low(color: Colors.green),
  medium(color: Colors.orange),
  high(color: Colors.red);

  final Color color;
  const Priority({required this.color});

  static Priority fromString(String priorityString) {
    return Priority.values.firstWhere(
            (priority) => priority.name == priorityString,
        orElse: () => Priority.low
    );
  }
}

class ToDoDatabase {
  List toDoList = [];
  final _myBox = Hive.box('mybox');

  void createInitialData() {
    toDoList = [
      ["Make tutorials", false, "Study", "low"],
      ["Do Exercise", false, "Health/Exercise", "medium"]
    ];
    updateDataBase();
  }

  void loadData() {
    var storedList = _myBox.get("TODOLIST");
    if (storedList == null) {
      createInitialData();
    } else {
      toDoList = storedList.map<List>((item) {
        // Handle migration from old formats
        if (item is List && item.length == 2) {
          return [...item, "Work", "low"]; // Add default category and priority
        } else if (item.length == 3) {
          return [...item, "low"]; // Add default priority
        }
        return item;
      }).toList();
    }
  }

  void updateDataBase() {
    _myBox.put("TODOLIST", toDoList);
  }

  void addToDo(String task, {bool isCompleted = false, String category = "Work", Priority priority = Priority.low}) {
    toDoList.add([task, isCompleted, category, priority.name]);
    updateDataBase();
  }

  void updateTodoPriority(int index, Priority newPriority) {
    if (index >= 0 && index < toDoList.length) {
      toDoList[index][3] = newPriority.name;
      updateDataBase();
    }
  }

  void updateTodoCategory(int index, String newCategory) {
    if (index >= 0 && index < toDoList.length) {
      toDoList[index][2] = newCategory;
      updateDataBase();
    }
  }

  void deleteTask(int index) {
    if (index >= 0 && index < toDoList.length) {
      toDoList.removeAt(index);
      updateDataBase();
    }
  }

  List getSortedTodos() {
    List sortedList = List.from(toDoList);

    sortedList.sort((a, b) {
      Map<String, int> priorityOrder = {'high': 0, 'medium': 1, 'low': 2};

      // First by completion (uncompleted first)
      if (a[1] != b[1]) return a[1] ? 1 : -1;

      // Then by priority
      int priorityComparison = priorityOrder[a[3]]!.compareTo(priorityOrder[b[3]]!);
      if (priorityComparison != 0) return priorityComparison;

      // Finally by category
      return a[2].compareTo(b[2]);
    });

    return sortedList;
  }

  Color getPriorityColor(int index) {
    if (index >= 0 && index < toDoList.length) {
      return Priority.fromString(toDoList[index][3]).color;
    }
    return Priority.low.color;
  }
}
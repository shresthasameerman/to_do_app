import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/Utils/dialog_box.dart';
import 'package:to_do_app/Utils/todo_tile.dart';
import 'package:to_do_app/Pages/profile_page.dart';
import 'dart:io';

enum Priority {
  low(color: Colors.green),
  medium(color: Colors.orange),
  high(color: Colors.red);

  final Color color;
  const Priority({required this.color});

  String get displayName => name.capitalizeFirstLetter();

  static Priority fromString(String priorityString) {
    return Priority.values.firstWhere(
          (priority) => priority.name == priorityString,
      orElse: () => Priority.low,
    );
  }
}

extension StringExtension on String {
  String capitalizeFirstLetter() {
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
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Work';
  Priority _selectedPriority = Priority.low;
  bool _isDarkMode = true;
  final _myBox = Hive.box('mybox');
  List toDoList = [];
  final List<String> categories = ['Work', 'Study', 'Personal', 'Health/Exc'];
  final List<Priority> priorities = Priority.values;

  String userName = "User Name";
  String? profileImagePath;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadThemePreference();
    _loadUserData();
  }

  void _initializeData() {
    if (_myBox.get("TODOLIST") == null) {
      _createInitialData();
    } else {
      _loadData();
    }
  }

  void _createInitialData() {
    toDoList = [
      ["Watch tutorial", false, "Study", "low", "Learn about Flutter basics."],
      ["Exercise", false, "Health/Exc", "medium", "Morning workout routine."],
    ];
    _myBox.put("TODOLIST", toDoList);
  }

  void _loadData() {
    toDoList = _myBox.get("TODOLIST");
    _sortTasksByPriority();
  }

  void _sortTasksByPriority() {
    toDoList.sort((a, b) {
      Priority priorityA = Priority.fromString(a[3]);
      Priority priorityB = Priority.fromString(b[3]);
      return priorityB.index.compareTo(priorityA.index); // High to Low
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

  void _loadUserData() {
    final savedName = _myBox.get("USER_NAME");
    final savedProfileImage = _myBox.get("PROFILE_IMAGE");

    if (savedName != null) {
      setState(() {
        userName = savedName;
      });
    }

    if (savedProfileImage != null) {
      setState(() {
        profileImagePath = savedProfileImage;
      });
    }
  }

  void _saveThemePreference() {
    _myBox.put("THEME_MODE", _isDarkMode);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _saveThemePreference();
    });
    Navigator.pop(context);
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) {
      _loadUserData();
    });
  }

  void _updateDatabase() {
    _sortTasksByPriority();
    _myBox.put("TODOLIST", toDoList);
  }

  void checkBoxChanged(bool value, int index) {
    setState(() {
      toDoList[index][1] = value;
      _updateDatabase();
    });
  }

  void saveNewTask() {
    setState(() {
      toDoList.add([
        _controller.text,
        false,
        _selectedCategory,
        _selectedPriority.name,
        _descriptionController.text,
      ]);
      _controller.clear();
      _descriptionController.clear();
      _updateDatabase();
    });
    Navigator.of(context).pop();
  }

  void createNewTask() {
    _selectedPriority = Priority.low;

    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          descriptionController: _descriptionController,
          onSave: saveNewTask,
          onCancel: () => Navigator.of(context).pop(),
          categories: categories,
          selectedCategory: _selectedCategory,
          onCategoryChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue!;
            });
          },
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
      _updateDatabase();
    });
  }

  void editTask(int index, String newText, String newDescription, Color newColor) {
    setState(() {
      Priority newPriority = Priority.values.firstWhere(
            (p) => p.color == newColor,
        orElse: () => Priority.low,
      );
      toDoList[index][0] = newText;
      toDoList[index][3] = newPriority.name;
      toDoList[index][4] = newDescription;
      _updateDatabase();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildTaskView(Map<String, List> categorizedTasks) {
    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          Material(
            color: _isDarkMode ? Colors.grey[900] : Colors.white,
            child: TabBar(
              isScrollable: true,
              indicatorColor: Colors.blue,
              labelColor: _isDarkMode ? Colors.white : Colors.blue,
              unselectedLabelColor: _isDarkMode ? Colors.grey : Colors.grey[700],
              tabs: categories.map((category) => Tab(text: category)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: categories.map((category) {
                final categoryTasks = (categorizedTasks[category] ?? [])
                  ..sort((a, b) {
                    Priority priorityA = Priority.fromString(a[3]);
                    Priority priorityB = Priority.fromString(b[3]);
                    return priorityB.index.compareTo(priorityA.index); // High to Low
                  });

                return categoryTasks.isEmpty
                    ? Center(
                  child: Text(
                    'No tasks in this category',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: categoryTasks.length,
                  itemBuilder: (context, index) {
                    return ToDoTile(
                      taskName: categoryTasks[index][0],
                      taskDescription: categoryTasks[index][4],
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
                      isDarkMode: _isDarkMode,
                      onEdit: (newText, newDescription, newColor) {
                        int originalIndex = toDoList.indexOf(categoryTasks[index]);
                        editTask(originalIndex, newText, newDescription, newColor);
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = _isDarkMode
        ? ThemeData.dark().copyWith(
      primaryColor: Colors.blue,
      appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]),
      scaffoldBackgroundColor: Colors.grey[900],
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
      ),
    )
        : ThemeData.light().copyWith(
      primaryColor: Colors.blue,
      appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
      ),
    );

    Map<String, List> categorizedTasks = {};
    for (var category in categories) {
      categorizedTasks[category] = toDoList.where((task) => task[2] == category).toList();
    }

    return Theme(
      data: themeData,
      child: Scaffold(
        endDrawer: _buildDrawer(),
        appBar: AppBar(
          title: const Text('Taskora'),
          elevation: 0,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: 'Menu',
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createNewTask,
          child: const Icon(Icons.add),
        ),
        body: _buildTaskView(categorizedTasks),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: _isDarkMode ? Colors.grey[850] : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: profileImagePath != null
                            ? Image.file(
                          File(profileImagePath!),
                          fit: BoxFit.cover,
                        )
                            : const Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tap to view profile',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.home,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'Home',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                _isDarkMode ? 'Light Mode' : 'Dark Mode',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: _toggleTheme,
            ),
          ],
        ),
      ),
    );
  }
}
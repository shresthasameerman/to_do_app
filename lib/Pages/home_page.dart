import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/Utils/dialog_box.dart';
import 'package:to_do_app/Utils/todo_tile.dart';
import 'package:to_do_app/Pages/profile_page.dart';
import 'package:to_do_app/Pages/study_timer_page.dart';
import 'package:to_do_app/Pages/CategoryPage.dart'; // Import the new category page
import 'dart:io';

enum Priority {
  low(color: Colors.green),
  medium(color: Colors.orange),
  high(color: Colors.red);

  final Color color;
  const Priority({required this.color});

  static Priority fromString(String priorityString) {
    return Priority.values.firstWhere(
          (priority) => priority.name == priorityString,
      orElse: () => Priority.low,
    );
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
  Priority _selectedPriority = Priority.low;
  final _myBox = Hive.box('mybox');
  List toDoList = [];
  String _selectedCategory = 'All';
  // Changed from final List to a regular List to allow reordering
  List<String> categories = ['All', 'Work', 'Personal', 'Health', 'Study'];

  bool _isDarkMode = true;
  String userName = "Guest";
  String? profileImagePath;

  // Theme data for light and dark modes
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;

  @override
  void initState() {
    super.initState();
    _initThemes();
    _initializeData();
    _loadUserData();
    _loadThemePreference();
    _loadCategoryOrder(); // Load the saved category order
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
        titleMedium: TextStyle(color: Colors.black87),
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
      ),
    );
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
      ["Learn Flutter", false, "Work", "low", "Start with Flutter basics."],
      ["Workout", false, "Health", "medium", "Morning exercise routine."],
    ];
    _myBox.put("TODOLIST", toDoList);
  }

  void _loadData() {
    toDoList = _myBox.get("TODOLIST");
  }

  void _updateDatabase() {
    _myBox.put("TODOLIST", toDoList);
  }

  void _loadUserData() {
    userName = _myBox.get("USERNAME") ?? "Guest";
    profileImagePath = _myBox.get("PROFILE_IMAGE");
  }

  void _saveThemePreference() {
    _myBox.put("THEME_MODE", _isDarkMode);
  }

  void _loadThemePreference() {
    _isDarkMode = _myBox.get("THEME_MODE") ?? true;
  }

  // Method to save the category order
  void _saveCategoryOrder() {
    _myBox.put("CATEGORIES_ORDER", categories);
  }

  // Method to load the saved category order
  void _loadCategoryOrder() {
    final savedCategories = _myBox.get("CATEGORIES_ORDER");
    if (savedCategories != null) {
      setState(() {
        categories = List<String>.from(savedCategories);
      });
    }
  }

  // Method to handle category reordering
  void _reorderCategories(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String category = categories.removeAt(oldIndex);
      categories.insert(newIndex, category);
      _saveCategoryOrder();
    });
  }

  void saveNewTask() {
    setState(() {
      toDoList.add([
        _controller.text,
        false,
        _selectedCategory == 'All' ? 'Work' : _selectedCategory, // Default to 'Work' if 'All' is selected
        _selectedPriority.name,
        _descriptionController.text,
      ]);
      _controller.clear();
      _descriptionController.clear();
      _updateDatabase();
    });
    Navigator.of(context).pop();
  }

  void deleteTask(int index) {
    setState(() {
      toDoList.removeAt(index);
      _updateDatabase();
    });
  }

  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          descriptionController: _descriptionController,
          onSave: saveNewTask,
          onCancel: () => Navigator.of(context).pop(),
          priorities: Priority.values.map((p) => p.name).toList(),
          selectedPriority: _selectedPriority.name,
          categories: categories.where((c) => c != 'All').toList(), // Exclude 'All' from new task creation
          selectedCategory: _selectedCategory == 'All' ? 'Work' : _selectedCategory,
          onPriorityChanged: (String? newValue) {
            setState(() {
              _selectedPriority = Priority.fromString(newValue ?? "low");
            });
          },
          onCategoryChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue ?? 'Work';
            });
          },
        );
      },
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) {
      setState(() {
        _loadUserData();
      });
    });
  }

  void _navigateToStudyTimer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudyTimerPage()),
    );
  }

  // New method to navigate to the categories page
  void _navigateToCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryPage()),
    ).then((_) {
      // Refresh the categories and selected category when returning
      setState(() {
        _loadCategoryOrder();
        // Make sure the selected category still exists
        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }
      });
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _saveThemePreference();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Widget to display profile image with proper handling for different sources
  Widget _buildProfileImage() {
    if (profileImagePath == null || profileImagePath!.isEmpty) {
      // No image set, show default icon
      return const CircleAvatar(
        radius: 36,
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, size: 40, color: Colors.white),
      );
    }

    // Check if the path is a file path or an asset path
    if (profileImagePath!.startsWith('assets/')) {
      // Asset image
      return CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white24,
        backgroundImage: AssetImage(profileImagePath!),
      );
    } else {
      // File image (from camera or gallery)
      final file = File(profileImagePath!);
      if (!file.existsSync()) {
        // File doesn't exist, show default icon
        return const CircleAvatar(
          radius: 36,
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, size: 40, color: Colors.white),
        );
      }

      return CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white24,
        backgroundImage: FileImage(file),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply appropriate theme based on _isDarkMode
    Theme.of(context).copyWith(
      colorScheme: _isDarkMode
          ? ColorScheme.dark(primary: Colors.blue)
          : ColorScheme.light(primary: Colors.blue),
    );

    final filteredTasks = _selectedCategory == 'All'
        ? toDoList
        : toDoList.where((task) => task[2] == _selectedCategory).toList();

    return Theme(
      data: _isDarkMode ? _darkTheme : _lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Taskora"),
          actions: [
            // Hamburger menu on the right
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            ),
          ],
        ),
        // Add the endDrawer for right-side hamburger menu
        endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.blue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Using our improved profile image widget
                    _buildProfileImage(),
                    const SizedBox(height: 10),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _navigateToProfile();
                },
              ),
              // Add the new Study Timer option
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Study Timer'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _navigateToStudyTimer();
                },
              ),
              ListTile(
                leading: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                title: Text(_isDarkMode ? 'Light Mode' : 'Dark Mode'),
                onTap: () {
                  _toggleTheme();
                  Navigator.pop(context); // Close the drawer
                },
              ),
              const Divider(),
              // Updated Categories option to use the new page
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categories'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _navigateToCategories(); // Use the new navigation method
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // Navigate to settings page
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Feedback'),
                onTap: () {
                  // Navigate to help page
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  // Show about dialog
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'Taskora',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 Taskora',
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createNewTask,
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            // Improved category selector with drag and drop
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Category: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Add a hint for users about reordering
                      Text(
                        "Long press & drag to reorder",
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Implement ReorderableList for category chips
                  SizedBox(
                    height: 40, // Fixed height for the category row
                    child: ReorderableListView(
                      scrollDirection: Axis.horizontal,
                      onReorder: _reorderCategories,
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget? child) {
                            final double animValue = Curves.easeInOut.transform(animation.value);
                            final double elevation = lerpDouble(0, 6, animValue)!;
                            return Material(
                              elevation: elevation,
                              color: Colors.transparent,
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      children: categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          key: ValueKey(category),
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            selectedColor: Colors.blue,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (_isDarkMode ? Colors.white : Colors.black),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            avatar: isSelected ? null : Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No tasks available.",
                      style: TextStyle(
                        fontSize: 18,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: createNewTask,
                      icon: const Icon(Icons.add),
                      label: const Text("Add your first task"),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return ToDoTile(
                    taskName: task[0],
                    taskDescription: task[4],
                    taskCompleted: task[1],
                    priorityColor: Priority.fromString(task[3]).color,
                    onChanged: (value) {
                      setState(() {
                        final originalIndex = toDoList.indexOf(task);
                        toDoList[originalIndex][1] = value ?? false;
                        _updateDatabase();
                      });
                    },
                    deleteFunction: (context) {
                      final originalIndex = toDoList.indexOf(task);
                      deleteTask(originalIndex);
                    },
                    isDarkMode: _isDarkMode,
                    onEdit: (newText, newDescription, newColor) {
                      setState(() {
                        final originalIndex = toDoList.indexOf(task);
                        toDoList[originalIndex][0] = newText;
                        toDoList[originalIndex][3] = Priority.values
                            .firstWhere((p) => p.color == newColor)
                            .name;
                        toDoList[originalIndex][4] = newDescription;
                        _updateDatabase();
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated to use the new CategoryPage
  void _showManageCategories() {
    _navigateToCategories();
  }
}

// Helper function for animation
double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}
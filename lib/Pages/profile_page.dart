import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// This is the priority enum from home_page.dart
// You can move this to a separate file to avoid duplication
enum Priority {
  low(color: Colors.green),
  medium(color: Colors.orange),
  high(color: Colors.red);

  final Color color;
  const Priority({required this.color});

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static Priority fromString(String priorityString) {
    return Priority.values.firstWhere(
            (priority) => priority.name == priorityString,
        orElse: () => Priority.low
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _myBox = Hive.box('mybox');

  // User data
  String userName = "User Name";
  String? profileImagePath;
  bool _isDarkMode = true;

  // Task lists for different filters
  List allTasks = [];
  List completedTasks = [];
  List pendingTasks = [];
  List highPriorityTasks = [];
  List recentlyCompletedTasks = [];
  Map<String, List> tasksByCategory = {};

  // Currently selected filter
  String currentFilter = "All Tasks";

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserData();
    _loadThemePreference();
  }

  // Load tasks from Hive
  void _loadData() {
    allTasks = _myBox.get("TODOLIST") ?? [];

    // Filter tasks into different categories
    completedTasks = allTasks.where((task) => task[1] == true).toList();
    pendingTasks = allTasks.where((task) => task[1] == false).toList();
    highPriorityTasks = allTasks.where((task) => task[3] == "high").toList();

    // Get the 5 most recently completed tasks
    // (This is an approximation as we don't store completion dates)
    recentlyCompletedTasks = completedTasks.take(5).toList();

    // Group tasks by category
    tasksByCategory = {};
    for (var task in allTasks) {
      String category = task[2];
      if (!tasksByCategory.containsKey(category)) {
        tasksByCategory[category] = [];
      }
      tasksByCategory[category]!.add(task);
    }
  }

  // Load user data from Hive
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

  // Load theme preference
  void _loadThemePreference() {
    final savedTheme = _myBox.get("THEME_MODE");
    if (savedTheme != null) {
      setState(() {
        _isDarkMode = savedTheme;
      });
    }
  }

  // Save user name
  void _saveUserName(String name) {
    _myBox.put("USER_NAME", name);
    setState(() {
      userName = name;
    });
  }

  // Save profile image path
  void _saveProfileImage(String path) {
    _myBox.put("PROFILE_IMAGE", path);
    setState(() {
      profileImagePath = path;
    });
  }

  // Update profile picture
  Future<void> _updateProfilePicture() async {
    final ImagePicker _picker = ImagePicker();

    // Show dialog to choose between camera and gallery
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Change Profile Picture"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text("Take a picture"),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      _saveProfileImage(image.path);
                    }
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text("Select from gallery"),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      _saveProfileImage(image.path);
                    }
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                if (profileImagePath != null)
                  GestureDetector(
                    child: Text("Remove photo", style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        profileImagePath = null;
                        _myBox.delete("PROFILE_IMAGE");
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Edit user name
  void _editUserName() {
    final TextEditingController _controller = TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Name"),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Enter your name",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _saveUserName(_controller.text);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Get tasks based on current filter
  List _getFilteredTasks() {
    switch (currentFilter) {
      case "Completed Tasks":
        return completedTasks;
      case "Pending Tasks":
        return pendingTasks;
      case "High Priority":
        return highPriorityTasks;
      case "Recently Completed":
        return recentlyCompletedTasks;
      default:
      // Check if it's a category filter
        for (var category in tasksByCategory.keys) {
          if (currentFilter == category) {
            return tasksByCategory[category]!;
          }
        }
        return allTasks; // Default to all tasks
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue,
      ),
    );

    // Get tasks for the selected filter
    final filteredTasks = _getFilteredTasks();

    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _editUserName,
              tooltip: 'Edit Name',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header
              Container(
                padding: EdgeInsets.all(20),
                color: _isDarkMode ? Colors.grey[850] : Colors.blue,
                child: Column(
                  children: [
                    // Profile picture
                    GestureDetector(
                      onTap: _updateProfilePicture,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profileImagePath != null
                                  ? Image.file(
                                File(profileImagePath!),
                                fit: BoxFit.cover,
                              )
                                  : Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    // User name
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Tap on the photo to change",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Task summary section
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Task Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    // Task stats grid
                    Row(
                      children: [
                        _buildStatCard(
                          "Total Tasks",
                          allTasks.length.toString(),
                          Icons.assignment,
                          Colors.blue,
                        ),
                        SizedBox(width: 10),
                        _buildStatCard(
                          "Completed",
                          completedTasks.length.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatCard(
                          "Pending",
                          pendingTasks.length.toString(),
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        SizedBox(width: 10),
                        _buildStatCard(
                          "High Priority",
                          highPriorityTasks.length.toString(),
                          Icons.priority_high,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Task Filters",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip("All Tasks"),
                          _buildFilterChip("Completed Tasks"),
                          _buildFilterChip("Pending Tasks"),
                          _buildFilterChip("High Priority"),
                          _buildFilterChip("Recently Completed"),
                          ...tasksByCategory.keys.map((category) => _buildFilterChip(category)).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Task list
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$currentFilter (${filteredTasks.length})",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    filteredTasks.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "No tasks found",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskItem(filteredTasks[index]);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a stat card
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build a filter chip
  Widget _buildFilterChip(String label) {
    final isSelected = currentFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            currentFilter = label;
          });
        },
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
        selectedColor: Colors.blue,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : _isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  // Build a task item
  Widget _buildTaskItem(List task) {
    final String taskName = task[0];
    final bool isCompleted = task[1];
    final String category = task[2];
    final String priorityString = task[3];

    final Priority priority = Priority.fromString(priorityString);

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: priority.color,
          ),
        ),
        title: Text(
          taskName,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text("Category: $category"),
        trailing: isCompleted
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.circle_outlined),
      ),
    );
  }
}
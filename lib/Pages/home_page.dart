import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/Utils/dialog_box.dart';
import 'package:to_do_app/Utils/todo_tile.dart';
import 'package:to_do_app/Pages/profile_page.dart';
import 'package:to_do_app/Pages/study_timer_page.dart';
import 'package:to_do_app/Pages/CategoryPage.dart';
import 'package:to_do_app/Pages/login_page.dart';
import 'package:to_do_app/Pages/Notes_Page.dart';
import 'package:to_do_app/Pages/notification_settings_page.dart'; // Added import for notification settings page
import 'dart:io';

// Constants for Hive box keys
class HiveKeys {
  static const String todoList = "TODOLIST";
  static const String username = "USERNAME";
  static const String profileImage = "PROFILE_IMAGE";
  static const String themeMode = "THEME_MODE";
  static const String isLoggedIn = "IS_LOGGED_IN";
  static const String categoriesOrder = "CATEGORIES_ORDER";
  static const String rememberedEmail = "REMEMBERED_EMAIL";
  static const String rememberedPassword = "REMEMBERED_PASSWORD";
}

// Task priority enum with associated colors
enum Priority {
  low(color: Color(0xFF4CAF50)),      // Improved green shade
  medium(color: Color(0xFFFFA726)),   // Improved orange shade
  high(color: Color(0xFFE53935));      // Improved red shade

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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Controllers
  final _controller = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();
  late final AnimationController _fabAnimationController;

  // Local state
  Priority _selectedPriority = Priority.low;
  final _myBox = Hive.box('mybox');
  List toDoList = [];
  String _selectedCategory = 'All';
  List<String> categories = ['All', 'Work', 'Personal', 'Health', 'Study'];

  bool _isDarkMode = true;
  bool _isSigningOut = false;
  String userName = "Guest";
  String? profileImagePath;
  bool _isScrolled = false;

  // Theme definitions
  late final ThemeData _lightTheme;
  late final ThemeData _darkTheme;

  @override
  void initState() {
    super.initState();
    _initThemes();
    _initializeData();
    _loadUserData();
    _loadThemePreference();
    _loadCategoryOrder();

    // Initialize animation controller for FAB
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Add scroll listener for app bar elevation
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 0;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  void _initThemes() {
    // Light theme configuration
    _lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue,
        labelStyle: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
    );

    // Dark theme configuration
    _darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800],
        selectedColor: Colors.blue[700],
        labelStyle: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2A2A2A),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
    );
  }

  void _initializeData() {
    if (_myBox.get(HiveKeys.todoList) == null) {
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
    _myBox.put(HiveKeys.todoList, toDoList);
  }

  void _loadData() {
    toDoList = _myBox.get(HiveKeys.todoList);
  }

  void _updateDatabase() {
    _myBox.put(HiveKeys.todoList, toDoList);
  }

  void _loadUserData() {
    userName = _myBox.get(HiveKeys.username, defaultValue: "Guest");
    profileImagePath = _myBox.get(HiveKeys.profileImage);
  }

  void _saveThemePreference() {
    _myBox.put(HiveKeys.themeMode, _isDarkMode);
  }

  void _loadThemePreference() {
    _isDarkMode = _myBox.get(HiveKeys.themeMode, defaultValue: true);
  }

  void _saveCategoryOrder() {
    _myBox.put(HiveKeys.categoriesOrder, categories);
  }

  void _loadCategoryOrder() {
    final savedCategories = _myBox.get(HiveKeys.categoriesOrder);
    if (savedCategories != null) {
      setState(() {
        categories = List<String>.from(savedCategories);
      });
    }
  }

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
    // Validate input
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty')),
      );
      return;
    }

    setState(() {
      toDoList.add([
        _controller.text,
        false,
        _selectedCategory == 'All' ? 'Work' : _selectedCategory,
        _selectedPriority.name,
        _descriptionController.text,
      ]);
      _controller.clear();
      _descriptionController.clear();
      _updateDatabase();
    });
    Navigator.of(context).pop();

    // Show animation for new task confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task added successfully'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              toDoList.removeLast();
              _updateDatabase();
            });
          },
        ),
      ),
    );
  }

  void deleteTask(int index) {
    // Store task for undo functionality
    final deletedTask = toDoList[index];

    setState(() {
      toDoList.removeAt(index);
      _updateDatabase();
    });

    // Show undo option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              toDoList.insert(index, deletedTask);
              _updateDatabase();
            });
          },
        ),
      ),
    );
  }

  void createNewTask() {
    // Reset values for new task
    _selectedPriority = Priority.low;
    _controller.clear();
    _descriptionController.clear();

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
          categories: categories.where((c) => c != 'All').toList(),
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

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      // Clear user-specific data but retain profile picture
      await _myBox.put(HiveKeys.isLoggedIn, false);
      await _myBox.put(HiveKeys.username, "Guest");
      await _myBox.delete(HiveKeys.rememberedEmail);
      await _myBox.delete(HiveKeys.rememberedPassword);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) {
      if (mounted) {
        setState(() {
          _loadUserData(); // Reload user data to fetch the updated profile picture
        });
      }
    });
  }

  void _navigateToStudyTimer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudyTimerPage()),
    );
  }

  void _navigateToCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryPage()),
    ).then((_) {
      if (mounted) {
        setState(() {
          _loadCategoryOrder();
          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'All';
          }
        });
      }
    });
  }

  // New method to navigate to notification settings
  void _navigateToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _saveThemePreference();
    });
  }

  Widget _buildProfileImage() {
    if (profileImagePath == null || profileImagePath!.isEmpty) {
      return const CircleAvatar(
        radius: 36,
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, size: 40, color: Colors.white),
      );
    }

    if (profileImagePath!.startsWith('assets/')) {
      return CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white24,
        backgroundImage: AssetImage(profileImagePath!),
      );
    } else {
      final file = File(profileImagePath!);
      if (!file.existsSync()) {
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
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _selectedCategory == 'All'
        ? List.from(toDoList)
        : toDoList.where((task) => task[2] == _selectedCategory).toList();

    return Theme(
      data: _isDarkMode ? _darkTheme : _lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Taskora"),
          elevation: _isScrolled ? 4 : 0,
          actions: [
            // Added notification icon in the app bar
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: _navigateToNotificationSettings,
              tooltip: 'Notification Settings',
            ),
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
              tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            ),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.blue,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildProfileImage(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Manage your tasks efficiently",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToProfile();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.note,
                  title: 'Notes',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotesPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.timer,
                  title: 'Study Timer',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToStudyTimer();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Categories',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToCategories();
                  },
                ),
                // Added notification settings option in the drawer
                _buildDrawerItem(
                  icon: Icons.notifications,
                  title: 'Notification Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToNotificationSettings();
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Add settings navigation here
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    // Add help navigation here
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'Taskora',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2025 Taskora',
                      applicationIcon: Image.asset(
                        'assets/app_icon.png',
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.task_alt, size: 48, color: Colors.blue),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: _isSigningOut
                      ? null
                      : Icons.logout,
                  title: 'Sign Out',
                  onTap: _isSigningOut ? null : _signOut,
                  trailing: _isSigningOut
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : null,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _fabAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_fabAnimationController.value * 0.1),
              child: FloatingActionButton.extended(
                onPressed: () {
                  _fabAnimationController.forward().then((_) {
                    _fabAnimationController.reverse();
                  });
                  createNewTask();
                },
                icon: const Icon(Icons.add),
                label: const Text("New Task"),
                elevation: 4,
              ),
            );
          },
        ),
        body: Column(
          children: [
            _buildCategorySelector(),
            Expanded(
              child: filteredTasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(filteredTasks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData? icon,
    required String title,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: _isDarkMode ? Colors.white70 : Colors.grey[800])
          : const SizedBox(width: 24),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Text(
                "My Categories",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
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
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    avatar: isSelected
                        ? Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.white,
                    )
                        : Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isSelected
                          ? BorderSide.none
                          : BorderSide(
                        color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No tasks in this category",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Add a new task to get started",
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: createNewTask,
            icon: const Icon(Icons.add),
            label: const Text("Add your first task"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List filteredTasks) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80), // Add space for FAB
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        final originalIndex = toDoList.indexOf(task);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ToDoTile(
            taskName: task[0],
            taskDescription: task[4],
            taskCompleted: task[1],
            priorityColor: Priority.fromString(task[3]).color,
            onChanged: (value) {
              setState(() {
                toDoList[originalIndex][1] = value ?? false;
                _updateDatabase();
              });
            },
            deleteFunction: (context) => deleteTask(originalIndex),
            isDarkMode: _isDarkMode,
            onEdit: (newText, newDescription, newColor) {
              setState(() {
                toDoList[originalIndex][0] = newText;
                toDoList[originalIndex][3] = Priority.values
                    .firstWhere((p) => p.color == newColor)
                    .name;
                toDoList[originalIndex][4] = newDescription;
                _updateDatabase();
              });
            },
          ),
        );
      },
    );
  }
}

double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}
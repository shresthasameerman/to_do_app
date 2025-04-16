import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:math' as math;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _myBox = Hive.box('mybox');
  final _formKey = GlobalKey<FormState>();

  String? profileImagePath;
  bool _isDarkMode = true;
  bool _isTaskListExpanded = false;
  List<dynamic> _allTasks = [];

  // Task statistics
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _highPriorityTasks = 0;
  int _lowPriorityTasks = 0;

  // Category statistics
  Map<String, int> _categoryStats = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadThemePreference();
    _calculateTaskStats();
  }

  void _loadUserData() {
    _nameController.text = _myBox.get("USERNAME") ?? "User";
    profileImagePath = _myBox.get("PROFILE_IMAGE");
  }

  void _loadThemePreference() {
    _isDarkMode = _myBox.get("THEME_MODE") ?? true;
  }

  void _calculateTaskStats() {
    final taskList = _myBox.get("TODOLIST") ?? [];
    _allTasks = List.from(taskList); // Store all tasks

    int completed = 0;
    int pending = 0;
    int highPriority = 0;
    int lowPriority = 0;
    Map<String, int> categoryMap = {};

    for (var task in taskList) {
      // Update completed/pending count
      if (task[1] == true) {
        completed++;
      } else {
        pending++;
      }

      // Update priority counts
      if (task[3] == "high") {
        highPriority++;
      } else if (task[3] == "low") {
        lowPriority++;
      }

      // Update category stats
      String category = task[2] ?? "Uncategorized";
      if (categoryMap.containsKey(category)) {
        categoryMap[category] = categoryMap[category]! + 1;
      } else {
        categoryMap[category] = 1;
      }
    }

    setState(() {
      _completedTasks = completed;
      _pendingTasks = pending;
      _highPriorityTasks = highPriority;
      _lowPriorityTasks = lowPriority;
      _categoryStats = categoryMap;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      _myBox.put("USERNAME", _nameController.text);
      _myBox.put("PROFILE_IMAGE", profileImagePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    }
  }

  // Show a bottom sheet with profile picture options
  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Profile Picture",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Take a new photo
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: Text(
                    "Take a photo",
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),

                // Option 2: Choose from gallery
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: const Icon(Icons.photo_library, color: Colors.green),
                  ),
                  title: Text(
                    "Choose from gallery",
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),

                // Only show the remove option if there's an existing profile image
                if (profileImagePath != null)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.2),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: Text(
                      "Remove photo",
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),

                const SizedBox(height: 8),

                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Remove the profile image
  void _removeProfileImage() {
    // Remove the file if it exists
    if (profileImagePath != null) {
      try {
        File(profileImagePath!).delete();
      } catch (e) {
        debugPrint('Error deleting profile image: $e');
      }
    }

    // Update state and show notification
    setState(() {
      profileImagePath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile picture removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Pick an image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 600, // Increased size for better quality
        maxHeight: 600,
        imageQuality: 85, // Adjust quality for better results
      );

      if (image != null) {
        // Create a unique filename with timestamp to avoid overwriting
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final directory = await path_provider.getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/profile_image_$timestamp.jpg';

        // Copy the image to app storage
        await File(image.path).copy(imagePath);

        // Delete the old profile image if exists
        if (profileImagePath != null) {
          try {
            File(profileImagePath!).delete();
          } catch (e) {
            debugPrint('Error deleting old profile image: $e');
          }
        }

        setState(() {
          profileImagePath = imagePath;
        });

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Preview the profile image in full screen
  void _previewProfileImage() {
    if (profileImagePath != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('Profile Picture', style: TextStyle(color: Colors.white)),
              actions: [
                // Edit button in preview
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pop(context);
                    _showProfileImageOptions();
                  },
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(
                  File(profileImagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _toggleTaskList() {
    setState(() {
      _isTaskListExpanded = !_isTaskListExpanded;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define text color based on dark mode
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.blue,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Image with improved UI
              Center(
                child: Stack(
                  children: [
                    // Profile image with tap behavior
                    GestureDetector(
                      onTap: profileImagePath != null
                          ? _previewProfileImage  // Preview if image exists
                          : _showProfileImageOptions,  // Options if no image
                      child: Hero(
                        tag: 'profileImage',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            border: Border.all(
                              color: Colors.blue,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            image: profileImagePath != null
                                ? DecorationImage(
                              image: FileImage(File(profileImagePath!)),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: profileImagePath == null
                              ? Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),

                    // Edit button overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showProfileImageOptions,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isDarkMode ? Colors.grey[900]! : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Username field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextFormField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Your Name',
                    hintStyle: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor, // Use dynamic text color
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ),

              // Rest of your existing code remains the same...
              const SizedBox(height: 24),

              // 2x2 Grid of statistics
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Completed Tasks
                  _buildStatCard(
                    "Completed Tasks",
                    _completedTasks.toString(),
                    Icons.check_circle_outline,
                    Colors.green,
                    textColor,
                  ),

                  // High Priority Tasks
                  _buildStatCard(
                    "High Priority",
                    _highPriorityTasks.toString(),
                    Icons.priority_high,
                    Colors.red,
                    textColor,
                  ),

                  // Pending Tasks
                  _buildStatCard(
                    "Pending Tasks",
                    _pendingTasks.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                    textColor,
                  ),

                  // Low Priority Tasks
                  _buildStatCard(
                    "Low Priority",
                    _lowPriorityTasks.toString(),
                    Icons.low_priority,
                    Colors.blue,
                    textColor,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Task Data Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
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
                          "Task Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor, // Use dynamic text color
                          ),
                        ),
                        // View Tasks Button
                        TextButton.icon(
                          onPressed: _toggleTaskList,
                          icon: Icon(
                            _isTaskListExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.blue,
                          ),
                          label: Text(
                            _isTaskListExpanded ? "Hide Tasks" : "View Tasks",
                            style: const TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Expandable Task List
                    if (_isTaskListExpanded) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        "Your Tasks",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor, // Use dynamic text color
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTaskList(textColor, secondaryTextColor),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    // Progress bar for completed vs total
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Task Completion",
                              style: TextStyle(
                                color: textColor, // Use dynamic text color
                              ),
                            ),
                            Text(
                              "${_completedTasks}/${_completedTasks + _pendingTasks} tasks",
                              style: TextStyle(
                                color: secondaryTextColor, // Use dynamic secondary text color
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_completedTasks + _pendingTasks) > 0
                                ? _completedTasks / (_completedTasks + _pendingTasks)
                                : 0.0,
                            minHeight: 10,
                            backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Category breakdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Category Breakdown",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor, // Use dynamic text color
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._buildCategoryList(textColor, secondaryTextColor),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Task completion by status
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompletionPieChart(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem("Completed", Colors.green, textColor),
                              const SizedBox(height: 8),
                              _buildLegendItem("Pending", Colors.orange, textColor),
                              const SizedBox(height: 16),
                              Text(
                                "Completion Rate",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor, // Use dynamic text color
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (_completedTasks + _pendingTasks) > 0
                                    ? "${((_completedTasks / (_completedTasks + _pendingTasks)) * 100).toStringAsFixed(1)}%"
                                    : "0%",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Save Profile",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(Color textColor, Color secondaryTextColor) {
    // Existing method remains the same
    if (_allTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            "No tasks found",
            style: TextStyle(
              color: secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allTasks.length,
      itemBuilder: (context, index) {
        final task = _allTasks[index];
        final taskName = task[0] as String;
        final isCompleted = task[1] as bool;
        final category = task[2] as String? ?? "Uncategorized";
        final priority = task[3] as String? ?? "medium";

        Color priorityColor;
        switch (priority) {
          case "high":
            priorityColor = Colors.red;
            break;
          case "low":
            priorityColor = Colors.blue;
            break;
          default:
            priorityColor = Colors.orange;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted ? Colors.green : priorityColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                // Task details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskName,
                        style: TextStyle(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted
                              ? secondaryTextColor
                              : textColor, // Use dynamic text colors
                          fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Category chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Priority indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Rest of the existing methods remain the same
  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color textColor) {
    // Your existing method implementation
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor, // Use dynamic text color
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryList(Color textColor, Color secondaryTextColor) {
    // Your existing method implementation
    if (_categoryStats.isEmpty) {
      return [
        Text(
          "No categories found",
          style: TextStyle(
            color: secondaryTextColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    List<Widget> categoryWidgets = [];

    // Sort categories by count (descending)
    var sortedCategories = _categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedCategories) {
      categoryWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: textColor, // Use dynamic text color
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${entry.value} tasks",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return categoryWidgets;
  }

  Widget _buildCompletionPieChart() {
    // Your existing method implementation
    return SizedBox(
      height: 100,
      width: 100,
      child: CustomPaint(
        painter: PieChartPainter(
          completedPercentage: (_completedTasks + _pendingTasks) > 0
              ? _completedTasks / (_completedTasks + _pendingTasks)
              : 0.0,
          completedColor: Colors.green,
          pendingColor: Colors.orange,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color textColor) {
    // Your existing method implementation
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor, // Use dynamic text color
          ),
        ),
      ],
    );
  }
}

// Custom painter for the pie chart
class PieChartPainter extends CustomPainter {
  final double completedPercentage;
  final Color completedColor;
  final Color pendingColor;
  final bool isDarkMode;

  PieChartPainter({
    required this.completedPercentage,
    required this.completedColor,
    required this.pendingColor,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Background circle (pending tasks)
    final pendingPaint = Paint()
      ..color = pendingColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, pendingPaint);

    // Foreground arc (completed tasks)
    if (completedPercentage > 0) {
      final completedPaint = Paint()
        ..color = completedColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top (negative Y-axis)
        2 * math.pi * completedPercentage, // Arc angle based on percentage
        true, // Use center
        completedPaint,
      );
    }

    // Border
    final borderPaint = Paint()
      ..color = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, borderPaint);

    // Inner circle (for donut style)
    final innerCirclePaint = Paint()
      ..color = isDarkMode ? Colors.grey[800]! : Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.6, innerCirclePaint);

    // Inner circle border
    canvas.drawCircle(center, radius * 0.6, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
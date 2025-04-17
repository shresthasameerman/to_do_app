import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _myBox = Hive.box('mybox');
  final _noteController = TextEditingController();
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> notes = [];
  bool _isDarkMode = true;
  String _searchQuery = "";

  late ThemeData _lightTheme;
  late ThemeData _darkTheme;

  @override
  void initState() {
    super.initState();
    _initThemes();
    _loadUserData();
    _loadNotes();
    _loadThemePreference();
  }

  void _initThemes() {
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

  void _loadUserData() {
    _isDarkMode = _myBox.get('THEME_MODE', defaultValue: true);
  }

  void _loadThemePreference() {
    _isDarkMode = _myBox.get('THEME_MODE', defaultValue: true);
  }

  // Load notes from Hive storage
  void _loadNotes() {
    final savedNotes = _myBox.get("NOTES");
    if (savedNotes != null) {
      try {
        notes = List<Map<String, dynamic>>.from(
            savedNotes.map((item) => Map<String, dynamic>.from(item))
        );
      } catch (e) {
        // Initialize with empty data if there's an error
        _initializeEmptyNotes();
      }
    } else {
      // Initialize with empty data if nothing is saved
      _initializeEmptyNotes();
    }
  }

  void _initializeEmptyNotes() {
    // Add sample notes for demonstration
    notes = [
      {
        'title': 'Travel Plan',
        'content': 'Day 1:\n• Arrive in Dubai\n• Check into hotel\n• Dubai Mall\n• Burj Khalifa\n• Local Restaurant\n\nDay 2:\n• Dubai Miracle Garden...',
        'timestamp': DateTime.now().subtract(Duration(days: 2)).toString(),
        'color': Colors.blue[100]!.value,
      },
      {
        'title': 'In class notes',
        'content': 'Outlining your company\'s objectives, target market, competition, products or services, financial projections, and marketing strategies is essential to creating a business...',
        'timestamp': DateTime.now().subtract(Duration(days: 5)).toString(),
        'color': Colors.grey[100]!.value,
      },
      {
        'title': 'To Dos for Feb.',
        'content': '○ Learn UI/UX\n○ Fix the car\n○ Join Yoga Class\n○ Create a portfolio',
        'timestamp': DateTime.now().subtract(Duration(hours: 12)).toString(),
        'color': Colors.orange[100]!.value,
        'isChecklist': true,
      },
      {
        'title': 'Diary Entry',
        'content': 'This Note is locked by password.',
        'timestamp': DateTime.now().subtract(Duration(hours: 1)).toString(),
        'color': Colors.amber[100]!.value,
        'isLocked': true,
      },
      {
        'title': 'Homework',
        'content': 'Chapter 4 Pages 29-56',
        'timestamp': DateTime.now().subtract(Duration(days: 1)).toString(),
        'color': Colors.amber[100]!.value,
      },
      {
        'title': 'Travel Apps',
        'content': '• TripAdvisor\n• Wanderlog\n• Booking\n• Airbnb (Experiences)\n• Skyscanner\n• Hopper\n• Kayak...',
        'timestamp': DateTime.now().subtract(Duration(hours: 5)).toString(),
        'color': Colors.blue[100]!.value,
      },
    ];
  }

  // Save notes to Hive storage
  void _saveNotes() {
    _myBox.put("NOTES", notes);
  }

  // Add a new note
  void _addNewNote() {
    _titleController.clear();
    _noteController.clear();

    showDialog(
      context: context,
      builder: (context) {
        Color selectedColor = Colors.blue[100]!;

        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
                title: Text("Add New Note"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: "Title",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: "Note content",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text("Note Color:"),
                          SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _colorOption(Colors.blue[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.green[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.orange[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.pink[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.amber[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.grey[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final content = _noteController.text.trim();

                      if (content.isNotEmpty) {
                        setState(() {
                          notes.add({
                            'title': title.isEmpty ? 'Untitled' : title,
                            'content': content,
                            'timestamp': DateTime.now().toString(),
                            'color': selectedColor.value,
                            'isChecklist': content.contains("□") || content.contains("■") ||
                                content.contains("[ ]") || content.contains("[x]") ||
                                content.contains("○") || content.contains("●"),
                          });
                          _saveNotes();
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Note content cannot be empty")),
                        );
                      }
                    },
                    child: Text("Add"),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  Widget _colorOption(Color color, Color selectedColor, Function(Color) onTap) {
    final bool isSelected = color.value == selectedColor.value;
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  // Delete a note
  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
      _saveNotes();
    });
  }

  // Edit a note
  void _editNote(int index) {
    final noteData = notes[index];
    _titleController.text = noteData['title'] ?? 'Untitled';
    _noteController.text = noteData['content'];
    Color selectedColor = Color(noteData['color'] ?? Colors.blue[100]!.value);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
                title: Text("Edit Note"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: "Title",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: "Note content",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 10,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text("Note Color:"),
                          SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _colorOption(Colors.blue[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.green[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.orange[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.pink[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.amber[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                  _colorOption(Colors.grey[100]!, selectedColor, (color) => setState(() => selectedColor = color)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final content = _noteController.text.trim();
                      if (content.isNotEmpty) {
                        setState(() {
                          notes[index]['title'] = title.isEmpty ? 'Untitled' : title;
                          notes[index]['content'] = content;
                          notes[index]['color'] = selectedColor.value;
                          notes[index]['isChecklist'] = content.contains("□") ||
                              content.contains("■") ||
                              content.contains("[ ]") ||
                              content.contains("[x]") ||
                              content.contains("○") ||
                              content.contains("●");
                          _saveNotes();
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: Text("Save"),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // Filter notes based on search query
  List<Map<String, dynamic>> _getFilteredNotes() {
    List<Map<String, dynamic>> filteredNotes = List.from(notes);

    // Filter by search query if needed
    if (_searchQuery.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) =>
      (note['title']?.toString().toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
          note['content'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Sort by timestamp (newest first)
    filteredNotes.sort((a, b) {
      final dateA = DateTime.parse(a['timestamp']);
      final dateB = DateTime.parse(b['timestamp']);
      return dateB.compareTo(dateA);
    });

    return filteredNotes;
  }

  void _showSearch() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search notes...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    filled: true,
                    fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = "";
                  _searchController.clear();
                });
                Navigator.pop(context);
              },
              child: Text("Clear"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? _darkTheme : _lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Notes"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show options menu
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewNote,
          child: const Icon(Icons.add),
          backgroundColor: Colors.amber,
        ),
        body: Column(
          children: [
            // Search bar
            if (_searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          // Clear search
                        },
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: "Travel"),
                          decoration: InputDecoration(
                            hintText: "Search notes...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          readOnly: true,
                          onTap: _showSearch,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        margin: EdgeInsets.all(5),
                        child: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: _showSearch,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Search query indicator (if searching)
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Searching: "$_searchQuery"')),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchQuery = "";
                            _searchController.clear();
                          });
                        },
                        child: Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ),

            // Notes grid
            Expanded(
              child: _buildNotesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  // Build grid view for notes
  Widget _buildNotesGrid() {
    final filteredNotes = _getFilteredNotes();

    if (filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? "No matching notes found."
                  : "No notes available.",
              style: TextStyle(
                fontSize: 18,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: _addNewNote,
                icon: const Icon(Icons.add),
                label: const Text("Add your first note"),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.builder(
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: filteredNotes.length,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemBuilder: (context, index) {
          return _buildNoteTile(filteredNotes[index], index);
        },
      ),
    );
  }

  // Build a single note tile
  Widget _buildNoteTile(Map<String, dynamic> noteData, int index) {
    final title = noteData['title'] ?? 'Untitled';
    final content = noteData['content'] as String;
    final color = noteData['color'] != null ? Color(noteData['color']) : Colors.blue[100]!;
    final isLocked = noteData['isLocked'] == true;
    final isChecklist = noteData['isChecklist'] == true;

    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final originalIndex = notes.indexWhere((note) =>
          note['title'] == noteData['title'] &&
              note['content'] == noteData['content'] &&
              note['timestamp'] == noteData['timestamp']
          );

          if (originalIndex >= 0) {
            _editNote(originalIndex);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with lock icon if needed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (isLocked)
                    Icon(Icons.lock_outline, size: 18, color: Colors.black54),
                ],
              ),
              SizedBox(height: 8),

              // Note content - handle checklist differently
              if (isChecklist)
                ...content.split('\n').take(6).map((line) {
                  if (line.trim().startsWith("○") || line.trim().startsWith("[ ]") || line.trim().startsWith("□")) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line.replaceAll("○", "").replaceAll("[ ]", "").replaceAll("□", "").trim(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (line.trim().startsWith("●") || line.trim().startsWith("[x]") || line.trim().startsWith("■")) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line.replaceAll("●", "").replaceAll("[x]", "").replaceAll("■", "").trim(),
                              style: TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (line.trim().startsWith("•")) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("•", style: TextStyle(fontSize: 16, color: Colors.black87)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line.substring(1).trim(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                })
              else
                isLocked
                    ? Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                )
                    : Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),

              // Show "..." if text is truncated
              if (content.split('\n').length > 6 && isChecklist || content.length > 200 && !isChecklist)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "...",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),

              SizedBox(height: 8),

              // Footer - just timestamp (removed section label)
              Text(
                _formatTimestamp(noteData['timestamp']),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format timestamp to a readable format
  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      // Format as MM/DD/YY
      return "${dateTime.month}/${dateTime.day}/${dateTime.year.toString().substring(2)}";
    } else if (difference.inDays > 0) {
      // Show days ago
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      // Show hours ago
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      // Show minutes ago
      return "${difference.inMinutes}m ago";
    } else {
      // Just now
      return "Just now";
    }
  }

  // Long press to edit/delete notes
  void _showNoteOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit Note"),
                onTap: () {
                  Navigator.pop(context);
                  _editNote(index);
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy),
                title: Text("Duplicate Note"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final note = Map<String, dynamic>.from(notes[index]);
                    note['timestamp'] = DateTime.now().toString();
                    notes.add(note);
                    _saveNotes();
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete Note"),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNote(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Toggle theme mode
  void _toggleThemeMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _myBox.put('THEME_MODE', _isDarkMode);
    });
  }
}
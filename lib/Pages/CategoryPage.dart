import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _myBox = Hive.box('mybox');
  final _categoryController = TextEditingController();
  List<String> categories = [];
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
    _loadThemePreference();
  }

  void _loadCategoryData() {
    final savedCategories = _myBox.get("CATEGORIES_ORDER");
    if (savedCategories != null) {
      setState(() {
        categories = List<String>.from(savedCategories);
      });
    } else {
      setState(() {
        categories = ['All', 'Work', 'Personal', 'Health', 'Study'];
      });
    }
  }

  void _loadThemePreference() {
    setState(() {
      _isDarkMode = _myBox.get("THEME_MODE") ?? true;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _myBox.put("THEME_MODE", _isDarkMode);
    });
  }

  void _saveCategoryOrder() {
    _myBox.put("CATEGORIES_ORDER", categories);
  }

  void _addNewCategory(String category) {
    if (category.isNotEmpty && !categories.contains(category)) {
      setState(() {
        categories.add(category);
        _saveCategoryOrder();
      });
    }
  }

  void _deleteCategory(String category) {
    // Don't allow deletion of 'All' category
    if (category != 'All') {
      setState(() {
        categories.remove(category);
        _saveCategoryOrder();
      });
    }
  }

  void _editCategory(String oldCategory, String newCategory) {
    if (oldCategory != 'All' && newCategory.isNotEmpty && !categories.contains(newCategory)) {
      setState(() {
        final index = categories.indexOf(oldCategory);
        if (index != -1) {
          categories[index] = newCategory;
          _saveCategoryOrder();
        }
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

  void _showEditCategoryDialog(String category) {
    final TextEditingController editController = TextEditingController(text: category);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text(
            "Edit Category",
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(
              labelText: "Category Name",
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(
                color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
              fillColor: _isDarkMode ? Colors.grey[800] : Colors.white,
              filled: true,
            ),
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: _isDarkMode ? Colors.grey[300] : Colors.blue,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _editCategory(category, editController.text.trim());
                Navigator.pop(context);
              },
              child: Text(
                "Save",
                style: TextStyle(
                  color: _isDarkMode ? Colors.blue[300] : Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use theme-aware colors
    final backgroundColor = _isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = _isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = _isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final headerColor = _isDarkMode ? Colors.grey[800] : Colors.blue[50];
    final formBackgroundColor = _isDarkMode ? Colors.grey[850] : Colors.grey[100];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Manage Categories"),
        backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.blue,
        foregroundColor: _isDarkMode ? Colors.white : Colors.white,
        actions: [
          // Add theme toggle button
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: _isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
                    title: Text(
                      "Category Help",
                      style: TextStyle(color: textColor),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("• Long press and drag to reorder categories", style: TextStyle(color: textColor)),
                          const SizedBox(height: 8),
                          Text("• Tap the edit icon to rename a category", style: TextStyle(color: textColor)),
                          const SizedBox(height: 8),
                          Text("• Tap the delete icon to remove a category", style: TextStyle(color: textColor)),
                          const SizedBox(height: 8),
                          Text("• The 'All' category cannot be edited or deleted", style: TextStyle(color: textColor)),
                          const SizedBox(height: 8),
                          Text("• Use the form at the bottom to add new categories", style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Close",
                          style: TextStyle(
                            color: _isDarkMode ? Colors.blue[300] : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category counter and info
          Container(
            padding: const EdgeInsets.all(16),
            color: headerColor,
            child: Row(
              children: [
                Icon(Icons.category, color: textColor),
                const SizedBox(width: 12),
                Text(
                  "${categories.length} Categories",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Text(
                  "Long press to reorder",
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // List of categories
          Expanded(
            child: ReorderableListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  key: ValueKey(category),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  color: cardColor,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: getColorForCategory(category),
                      child: Text(
                        category.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: index == 0
                        ? Text(
                      "Default category (cannot be modified)",
                      style: TextStyle(color: secondaryTextColor),
                    )
                        : null,
                    trailing: category == 'All'
                        ? Icon(Icons.lock_outline, color: secondaryTextColor)
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: _isDarkMode ? Colors.blue[300] : Colors.blue),
                          onPressed: () => _showEditCategoryDialog(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
                                  title: Text(
                                    "Delete Category",
                                    style: TextStyle(color: textColor),
                                  ),
                                  content: Text(
                                    "Are you sure you want to delete '$category'? Tasks with this category will not be deleted, but you may need to reassign them.",
                                    style: TextStyle(color: textColor),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: _isDarkMode ? Colors.grey[300] : Colors.blue,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteCategory(category);
                                        Navigator.pop(context);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              onReorder: _reorderCategories,
            ),
          ),

          // Add new category form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: formBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      hintText: "Enter new category name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    style: TextStyle(
                      color: textColor,
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _addNewCategory(value.trim());
                        _categoryController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final text = _categoryController.text.trim();
                    if (text.isNotEmpty) {
                      _addNewCategory(text);
                      _categoryController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    backgroundColor: _isDarkMode ? Colors.blue[700] : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text("Add"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to generate consistent colors for categories
  Color getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Colors.blue;
      case 'work':
        return Colors.orange;
      case 'personal':
        return Colors.purple;
      case 'health':
        return Colors.green;
      case 'study':
        return Colors.red;
      default:
      // Generate a color based on the category name for consistency
        final int hash = category.hashCode;
        return Colors.primaries[hash % Colors.primaries.length];
    }
  }
}
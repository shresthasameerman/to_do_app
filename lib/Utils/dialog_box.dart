import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class DialogBox extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController descriptionController; // Added for description
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final List<String> priorities;
  final String selectedPriority;
  final ValueChanged<String?> onPriorityChanged;

  const DialogBox({
    Key? key,
    required this.controller,
    required this.descriptionController,
    required this.onSave,
    required this.onCancel,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.priorities,
    required this.selectedPriority,
    required this.onPriorityChanged,
  }) : super(key: key);

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  DateTime? _selectedDueDate; // Added for task due date
  bool _isUrgent = false; // Added for urgency
  bool _isImportant = false; // Added for importance

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Task Name
            TextField(
              controller: widget.controller,
              decoration: const InputDecoration(labelText: 'Task Name'),
            ),
            const SizedBox(height: 20),

            // Task Description
            TextField(
              controller: widget.descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: widget.selectedCategory,
              items: widget.categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: widget.onCategoryChanged,
            ),
            const SizedBox(height: 20),

            // Priority Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Priority'),
              value: widget.selectedPriority,
              items: widget.priorities.map((String priority) {
                Color priorityColor;
                switch (priority) {
                  case 'high':
                    priorityColor = Colors.red;
                    break;
                  case 'medium':
                    priorityColor = Colors.orange;
                    break;
                  case 'low':
                  default:
                    priorityColor = Colors.green;
                }
                return DropdownMenuItem<String>(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(priority.capitalize()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: widget.onPriorityChanged,
            ),
            const SizedBox(height: 20),

            // Due Date Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Due Date:"),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    setState(() {
                      _selectedDueDate = pickedDate;
                    });
                  },
                  child: Text(
                    _selectedDueDate == null
                        ? "Select Date"
                        : DateFormat('yyyy-MM-dd').format(_selectedDueDate!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDueDate == null
                          ? Colors.blue
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Urgency and Importance Toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isUrgent,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent = value!;
                        });
                      },
                    ),
                    const Text("Urgent"),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _isImportant,
                      onChanged: (value) {
                        setState(() {
                          _isImportant = value!;
                        });
                      },
                    ),
                    const Text("Important"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onSave();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
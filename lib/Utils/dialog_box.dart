import 'package:flutter/material.dart';

class DialogBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final List<String> categories;
  final String selectedCategory;
  final void Function(String?) onCategoryChanged;

  // New parameters for priority
  final List<String> priorities;
  final String selectedPriority;
  final void Function(String?) onPriorityChanged;

  const DialogBox({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    // New required parameters
    required this.priorities,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      content: SizedBox(
        height: 250, // Increased height to accommodate priority
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Task Input
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter task name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: const OutlineInputBorder(),
              ),
            ),

            // Category Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: Colors.grey[800],
              value: selectedCategory,
              items: categories
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(
                  category,
                  style: const TextStyle(color: Colors.white),
                ),
              ))
                  .toList(),
              onChanged: onCategoryChanged,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),

            // Priority Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: Colors.grey[800],
              value: selectedPriority,
              items: priorities
                  .map((priority) => DropdownMenuItem(
                value: priority,
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    color: _getPriorityColor(priority),
                  ),
                ),
              ))
                  .toList(),
              onChanged: onPriorityChanged,
              decoration: const InputDecoration(
                labelText: 'Select Priority',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Cancel button
        MaterialButton(
          onPressed: onCancel,
          color: Colors.grey[700],
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white),
          ),
        ),

        // Save button
        MaterialButton(
          onPressed: onSave,
          color: Colors.blue,
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Helper method to get color based on priority
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.white;
    }
  }
}
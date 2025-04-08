import 'package:flutter/material.dart';

class DialogBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final List<String> priorities;
  final String selectedPriority;
  final ValueChanged<String?> onPriorityChanged;
  final DateTime? reminderTime;
  final ValueChanged<DateTime?> onReminderTimeChanged;

  const DialogBox({
    Key? key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.priorities,
    required this.selectedPriority,
    required this.onPriorityChanged,
    required this.reminderTime,
    required this.onReminderTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Task Name'),
          ),
          const SizedBox(height: 20),
          // Other input fields like category, priority, reminder time
          // Use the provided parameters to handle changes and display current values
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(onPressed: onSave, child: const Text('Save')),
      ],
    );
  }
}
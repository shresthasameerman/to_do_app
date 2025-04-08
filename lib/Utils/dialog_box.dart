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
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Category'),
            value: selectedCategory,
            items: categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Priority'),
            value: selectedPriority,
            items: priorities.map((String priority) {
              Color priorityColor;
              switch (priority) {
                case 'high':
                  priorityColor = Colors.red;
                  break;
                case 'medium':
                  priorityColor = Colors.orange;
                  break;
                case 'low':
                  priorityColor = Colors.green;
                  break;
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
            onChanged: onPriorityChanged,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(onPressed: onSave, child: const Text('Save')),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
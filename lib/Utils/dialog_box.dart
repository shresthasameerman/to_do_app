import 'package:flutter/material.dart';

class DialogBox extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController descriptionController;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final List<String> priorities;
  final String selectedPriority;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<String?> onCategoryChanged;

  const DialogBox({
    Key? key,
    required this.controller,
    required this.descriptionController,
    required this.onSave,
    required this.onCancel,
    required this.priorities,
    required this.selectedPriority,
    required this.categories,
    required this.selectedCategory,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the task name field
    bool isTaskNameEmpty = controller.text.trim().isEmpty;

    return AlertDialog(
      title: const Text('Add New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Task Name',
                errorText: isTaskNameEmpty ? 'Task name is required' : null,
              ),
              onChanged: (value) {
                // This will trigger a rebuild when the text changes
                (context as Element).markNeedsBuild();
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: onCategoryChanged,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPriority,
              items: priorities.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority),
                );
              }).toList(),
              onChanged: onPriorityChanged,
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isTaskNameEmpty ? null : onSave, // Disable if empty
          child: const Text('Save'),
        ),
      ],
    );
  }
}
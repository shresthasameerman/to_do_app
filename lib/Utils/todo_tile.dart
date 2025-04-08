import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';  // Add this line to import the intl package

class ToDoTile extends StatefulWidget {
  final String taskName;
  final bool taskCompleted;
  final Color priorityColor;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFunction;
  final bool isDarkMode;
  final Function(String, Color, DateTime?, List<Map<String, String>>) onEdit;
  final DateTime? reminderTime;
  final List<Map<String, String>> subTasks;

  const ToDoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.priorityColor,
    required this.onChanged,
    required this.deleteFunction,
    required this.isDarkMode,
    required this.onEdit,
    required this.reminderTime,
    required this.subTasks,
  });

  @override
  State<ToDoTile> createState() => _ToDoTileState();
}

class _ToDoTileState extends State<ToDoTile> {
  late TextEditingController _editController;
  late Color _currentPriorityColor;
  late DateTime? _currentReminderTime;
  late List<Map<String, String>> _currentSubTasks;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.taskName);
    _currentPriorityColor = widget.priorityColor;
    _currentReminderTime = widget.reminderTime;
    _currentSubTasks = List<Map<String, String>>.from(widget.subTasks);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            'Edit Task',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editController,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _currentPriorityColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Priority:',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPriorityColorOption(Colors.red, 'High'),
                  _buildPriorityColorOption(Colors.orange, 'Medium'),
                  _buildPriorityColorOption(Colors.green, 'Low'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Reminder:',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentReminderTime == null
                          ? 'No reminder set'
                          : 'Reminder: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_currentReminderTime!)}',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.white),
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          final DateTime combinedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          setState(() {
                            _currentReminderTime = combinedDateTime;
                          });
                        }
                      }
                    },
                  ),
                  if (_currentReminderTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _currentReminderTime = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Sub-tasks:',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: _currentSubTasks.map((subTask) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: subTask['title']),
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Sub-task title',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            subTask['title'] = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: subTask['description']),
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Sub-task description',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            subTask['description'] = value;
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentSubTasks.add({'title': '', 'description': ''});
                  });
                },
                child: const Text('Add Sub-task', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                widget.onEdit(_editController.text, _currentPriorityColor, _currentReminderTime, _currentSubTasks);
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: _currentPriorityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityColorOption(Color color, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentPriorityColor = color;
        });
      },
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: _currentPriorityColor == color
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onLongPress: _showEditDialog,
        child: Slidable(
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              SlidableAction(
                onPressed: widget.deleteFunction,
                icon: Icons.delete,
                backgroundColor: Colors.red.shade300,
                borderRadius: BorderRadius.circular(12),
              )
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.priorityColor.withOpacity(0.2),
                  widget.isDarkMode ? Colors.grey[850]! : Colors.grey[200]!,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: widget.taskCompleted,
                          onChanged: widget.onChanged,
                          activeColor: widget.priorityColor,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: BorderSide(
                            color: widget.priorityColor,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: widget.priorityColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.priorityColor.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.taskName,
                          style: TextStyle(
                            decoration: widget.taskCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: widget.taskCompleted
                                ? Colors.grey
                                : widget.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.subTasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 48.0, top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.subTasks.map((subTask) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subTask['title']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                Text(
                                  subTask['description']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
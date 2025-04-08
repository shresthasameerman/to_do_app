import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ToDoTile extends StatefulWidget {
  final String taskName;
  final bool taskCompleted;
  final Color priorityColor;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFunction;
  final bool isDarkMode;
  final Function(String, Color) onEdit;

  const ToDoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.priorityColor,
    required this.onChanged,
    required this.deleteFunction,
    required this.isDarkMode,
    required this.onEdit,
  });

  @override
  State<ToDoTile> createState() => _ToDoTileState();
}

class _ToDoTileState extends State<ToDoTile> {
  late TextEditingController _editController;
  late Color _currentPriorityColor;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.taskName);
    _currentPriorityColor = widget.priorityColor;
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
                widget.onEdit(_editController.text, _currentPriorityColor);
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
              child: Row(
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
            ),
          ),
        ),
      ),
    );
  }
}
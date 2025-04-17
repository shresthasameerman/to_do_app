import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:to_do_app/Utils/add_note_dialog.dart';
import 'dart:io';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _myBox = Hive.box('mybox');
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final savedNotes = _myBox.get("NOTES");
    if (savedNotes != null) {
      setState(() {
        // Convert from dynamic map to Map<String, dynamic>
        notes = (savedNotes as List).map((item) =>
        Map<String, dynamic>.from(item as Map)).toList();
      });
    }
  }

  void _saveNotes() {
    _myBox.put("NOTES", notes);
  }

  void _addNewNote() {
    showDialog(
      context: context,
      builder: (context) {
        return AddNoteDialog(
          onAdd: (String title, String content, List<File> images) {
            setState(() {
              notes.add({
                'title': title,
                'content': content,
                'images': images.map((image) => image.path).toList(),
              });
              _saveNotes();
            });
          },
        );
      },
    );
  }

  void _editNote(int index) {
    final note = notes[index];
    showDialog(
      context: context,
      builder: (context) {
        return AddNoteDialog(
          initialTitle: note['title'],
          initialContent: note['content'],
          initialImages: (note['images'] as List?)
              ?.map((path) => File(path.toString()))
              .toList() ?? [],
          onAdd: (String title, String content, List<File> images) {
            setState(() {
              notes[index] = {
                'title': title,
                'content': content,
                'images': images.map((image) => image.path).toList(),
              };
              _saveNotes();
            });
          },
        );
      },
    );
  }

  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
      _saveNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewNote,
        child: const Icon(Icons.add),
      ),
      body: notes.isEmpty
          ? const Center(
        child: Text(
          "No notes yet. Tap + to add a new note.",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final images = (note['images'] as List?)
                ?.map((path) => File(path.toString()))
                .toList() ?? [];

            return Card(
              color: Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () => _editNote(index),
                onLongPress: () => _showDeleteDialog(context, index),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with delete button
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 4, top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with flexible to prevent overflow
                          Expanded(
                            child: note['title'] != null && note['title'].isNotEmpty
                                ? Text(
                              note['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                                : const SizedBox.shrink(),
                          ),
                          // Delete button that doesn't disrupt layout
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white70, size: 18),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => _showDeleteDialog(context, index),
                            tooltip: 'Delete note',
                          ),
                        ],
                      ),
                    ),

                    // Content padding
                    if (note['content'] != null && note['content'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          note['content'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),

                    // Images
                    if (images.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: images
                              .map(
                                (image) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[700],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                              .toList(),
                        ),
                      ),
                    // Add a small bottom padding if there are no images
                    if (images.isEmpty)
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteNote(index);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
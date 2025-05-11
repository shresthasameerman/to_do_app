import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _myBox = Hive.box('mybox');
  List<Map<String, dynamic>> notes = [];
  final SpeechToText _speechToText = SpeechToText();
  bool _speechInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadNotes();
  }

  void _initSpeech() async {
    _speechInitialized = await _speechToText.initialize();
    setState(() {});
  }

  void _loadNotes() {
    try {
      final savedNotes = _myBox.get("NOTES");
      if (savedNotes != null) {
        setState(() {
          notes = (savedNotes as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notes: $e')),
      );
    }
  }

  void _saveNotes() {
    try {
      _myBox.put("NOTES", notes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving notes: $e')),
      );
    }
  }

  void _addNewNote() {
    showDialog(
      context: context,
      builder: (context) {
        return AddNoteDialog(
          speechToText: _speechToText,
          speechInitialized: _speechInitialized,
          onAdd: (String title, String content, List<String> imageBase64) {
            setState(() {
              notes.add({
                'title': title,
                'content': content,
                'images': imageBase64,
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
          speechToText: _speechToText,
          speechInitialized: _speechInitialized,
          initialTitle: note['title'],
          initialContent: note['content'],
          initialImages: (note['images'] as List?)?.cast<String>() ?? [],
          onAdd: (String title, String content, List<String> imageBase64) {
            setState(() {
              notes[index] = {
                'title': title,
                'content': content,
                'images': imageBase64,
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

  void _showNoteDetails(int index) {
    final note = notes[index];
    final images = (note['images'] as List?)?.cast<String>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note['title']?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      note['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (note['content']?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      note['content'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                if (images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, imgIndex) {
                        try {
                          final bytes = base64Decode(images[imgIndex]);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                bytes,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
        elevation: 0,
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
            final images = (note['images'] as List?)?.cast<String>() ?? [];

            // Calculate dynamic height
            final hasTitle = note['title']?.isNotEmpty ?? false;
            final hasContent = note['content']?.isNotEmpty ?? false;
            final hasImages = images.isNotEmpty;

            double height = 120;
            if (hasTitle) height += 30;
            if (hasContent) height += 60;
            if (hasImages) height += 100;

            return GestureDetector(
              onTap: () => _showNoteDetails(index),
              child: Card(
                color: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.zero,
                child: Container(
                  height: height,
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasTitle)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                note['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (hasContent)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  note['content'],
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          if (hasImages)
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length > 2 ? 2 : images.length,
                                itemBuilder: (context, imgIndex) {
                                  try {
                                    final bytes = base64Decode(images[imgIndex]);
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.memory(
                                          bytes,
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
                                    );
                                  } catch (e) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[700],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.white70,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editNote(index);
                            } else if (value == 'delete') {
                              _showDeleteDialog(context, index);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
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

class AddNoteDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final List<String>? initialImages;
  final Function(String, String, List<String>) onAdd;
  final SpeechToText speechToText;
  final bool speechInitialized;

  const AddNoteDialog({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.initialImages,
    required this.onAdd,
    required this.speechToText,
    required this.speechInitialized,
  });

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _images = [];
  bool _isListening = false;
  String? _titleError;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _images = widget.initialImages?.toList() ?? [];
    _titleController.addListener(_validateFields);
    _contentController.addListener(_validateFields);
  }

  void _validateFields() {
    setState(() {
      _titleError = _titleController.text.trim().isEmpty ? 'Title is required' : null;
      _contentError = _contentController.text.trim().isEmpty ? 'Description is required' : null;
    });
  }

  void _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      List<String> newImages = [];
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        newImages.add(base64Encode(bytes));
      }
      setState(() {
        _images.addAll(newImages);
      });
    }
  }

  void _startListening() async {
    if (widget.speechInitialized && !_isListening) {
      await widget.speechToText.listen(
        onResult: (result) {
          setState(() {
            _contentController.text = result.recognizedWords;
            _validateFields();
          });
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await widget.speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_validateFields);
    _contentController.removeListener(_validateFields);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _titleError == null && _contentError == null;

    return AlertDialog(
      title: const Text('Add Note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _titleError,
              ),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Description',
                errorText: _contentError,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Add Images'),
            ),
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    try {
                      final bytes = base64Decode(_images[index]);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            bytes,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    } catch (e) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      );
                    }
                  },
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.speechInitialized
                  ? (_isListening ? _stopListening : _startListening)
                  : null,
              icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
              label: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isFormValid
              ? () {
            widget.onAdd(
              _titleController.text.trim(),
              _contentController.text.trim(),
              _images,
            );
            Navigator.pop(context);
          }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
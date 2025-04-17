import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:to_do_app/Utils/add_note_dialog.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _myBox = Hive.box('mybox');
  List<Map<String, dynamic>> notes = [];

  // Speech to text instance
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _initSpeech();
  }

  // Initialize speech recognition
  void _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (errorNotification) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorNotification')),
        );
      },
    );
  }

  void _loadNotes() {
    final savedNotes = _myBox.get("NOTES");
    if (savedNotes != null) {
      setState(() {
        // Fix: Properly convert from dynamic map to Map<String, dynamic>
        notes = (savedNotes as List).map((item) =>
        Map<String, dynamic>.from(item as Map)).toList();
      });
    }
  }

  void _saveNotes() {
    _myBox.put("NOTES", notes);
  }

  // Start quick voice note
  void _startQuickVoiceNote() async {
    if (!_speech.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available on this device')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
    );

    // Show the "listening" indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mic, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Listening... (${_recognizedText.length} chars)')),
            ],
          ),
          duration: const Duration(seconds: 30),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Stop',
            textColor: Colors.white,
            onPressed: _stopListeningAndSaveNote,
          ),
        ),
      );
    }
  }

  // Stop listening and save the note
  void _stopListeningAndSaveNote() {
    _speech.stop();
    setState(() => _isListening = false);

    if (_recognizedText.isNotEmpty) {
      // Show dialog to confirm and edit the transcribed text
      showDialog(
        context: context,
        builder: (context) {
          String title = '';
          String content = _recognizedText;

          return AlertDialog(
            title: const Text('Voice Note'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Title (Optional)',
                      hintText: 'Enter title',
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'Your transcribed note',
                    ),
                    controller: TextEditingController(text: content),
                    maxLines: 5,
                    onChanged: (value) => content = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    notes.add({
                      'title': title,
                      'content': content,
                      'images': <String>[],
                    });
                    _saveNotes();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice note saved!')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }
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
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : null,
            ),
            onPressed: _isListening ? _stopListeningAndSaveNote : _startQuickVoiceNote,
            tooltip: 'Quick voice note',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'voice',
            onPressed: _startQuickVoiceNote,
            backgroundColor: Colors.red,
            child: const Icon(Icons.mic),
            tooltip: 'Voice note',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addNewNote,
            child: const Icon(Icons.add),
            tooltip: 'Add note',
          ),
        ],
      ),
      body: notes.isEmpty
          ? const Center(
        child: Text(
          "No notes yet. Tap + to add a new note or mic to record a voice note.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
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

            return InkWell(
              onTap: () => _editNote(index),
              onLongPress: () => _showDeleteDialog(context, index),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note['title'] != null && note['title'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          note['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    if (note['content'] != null && note['content'].isNotEmpty)
                      Text(
                        note['content'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (images.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
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
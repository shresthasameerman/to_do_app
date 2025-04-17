import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';

class AddNoteDialog extends StatefulWidget {
  final Function(String title, String content, List<File> images) onAdd;
  final String? initialTitle;
  final String? initialContent;
  final List<File>? initialImages;

  const AddNoteDialog({
    Key? key,
    required this.onAdd,
    this.initialTitle,
    this.initialContent,
    this.initialImages,
  }) : super(key: key);

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;

  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];

  // Speech to text instance
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _activeField = 'content'; // 'title' or 'content'

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _noteController = TextEditingController(text: widget.initialContent ?? '');
    _images = widget.initialImages ?? [];
    _initSpeech();
  }

  // Initialize speech recognition
  void _initSpeech() async {
    bool available = await _speech.initialize(
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
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available on this device')),
      );
    }
  }

  // Toggle listening
  void _toggleListening(String field) {
    _activeField = field;

    if (!_isListening) {
      setState(() => _isListening = true);
      _startListening();
    } else {
      _stopListening();
    }
  }

  // Start listening
  void _startListening() async {
    await _speech.listen(
      onResult: (result) {
        if (_activeField == 'title') {
          setState(() {
            _titleController.text = result.recognizedWords;
          });
        } else {
          setState(() {
            _noteController.text = _noteController.text.isEmpty
                ? result.recognizedWords
                : '${_noteController.text} ${result.recognizedWords}';
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  // Stop listening
  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _addImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  Future<void> _addImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: "Title",
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isListening && _activeField == 'title'
                              ? Icons.mic : Icons.mic_none,
                          color: _isListening && _activeField == 'title'
                              ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _toggleListening('title'),
                        tooltip: 'Dictate title',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          maxLines: null,
                          minLines: 3,
                          decoration: const InputDecoration(
                            hintText: "Type your note...",
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isListening && _activeField == 'content'
                              ? Icons.mic : Icons.mic_none,
                          color: _isListening && _activeField == 'content'
                              ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _toggleListening('content'),
                        tooltip: 'Dictate note content',
                      ),
                    ],
                  ),
                  if (_isListening)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Listening... Speak now',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_images.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _images
                          .map(
                            (image) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _images.remove(image);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .toList(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _addImageFromCamera,
                    tooltip: 'Take photo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _addImageFromGallery,
                    tooltip: 'Choose from gallery',
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_isListening) {
                        _stopListening();
                      }
                      widget.onAdd(
                        _titleController.text.trim(),
                        _noteController.text.trim(),
                        _images,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
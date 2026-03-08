import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// Import your existing screens
import 'history_drawer.dart';
import 'settings_screen.dart';
import '../services/semantic_search_service.dart';
import '../services/document_indexer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _searchHistory = [];
  final TextEditingController _controller = TextEditingController();

  // UPDATED: Changed from String to Message object to handle image paths
  final List<Message> _messages = [];
  bool _isSearching = false;
  final SemanticSearchService _semanticSearchService = SemanticSearchService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _semanticSearchService.init();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyData = prefs.getString('search_history');
    if (historyData != null) {
      setState(() {
        _searchHistory = List<Map<String, String>>.from(
          json
              .decode(historyData)
              .map((item) => Map<String, String>.from(item)),
        );
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String historyData = json.encode(_searchHistory);
    await prefs.setString('search_history', historyData);
  }

  // UPDATED: This function now picks and adds images to the chat
  Future<void> _searchFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'pptx'],
    );

    if (result != null) {
      String path = result.files.first.path!;
      List<String> detectedLabels = [];

      setState(() {
        _messages.add(
          Message(text: "Indexing attached document...", isUser: false),
        );
      });

      // If it's an image, let the AI "see" it
      if (!path.toLowerCase().endsWith('.pdf') &&
          !path.toLowerCase().endsWith('.pptx')) {
        detectedLabels = await _getImageLabels(path);
      } else {
        // Trigger Semantic Indexer for PDFs and PPTXs
        final doc = await DocumentIndexer.analyzeDocument(path);
        if (doc != null) {
          await _semanticSearchService.saveDocumentToIndex(doc);
          setState(() {
            _messages.add(
              Message(
                text:
                    "Indexed Academic Doc: ${doc.title}\n\nSummary:\n${doc.summary}\n\nKeywords: ${doc.keywords.join(', ')}",
                filePath: path,
                isUser: false,
              ),
            );
          });
        } else {
          setState(() {
            _messages.add(
              Message(
                text: "Could not read text from this document.",
                isUser: false,
              ),
            );
          });
        }
      }

      setState(() {
        _messages.add(
          Message(
            text: "Attached: ${result.files.first.name}",
            filePath: path,
            isUser: true,
            labels: detectedLabels,
          ),
        );
      });
    }
  }

  Future<List<String>> _getImageLabels(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );

    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    List<String> labelTexts = labels
        .map((label) => label.label.toLowerCase())
        .toList();

    imageLabeler.close();
    return labelTexts;
  }

  Future<void> _performSemanticSearch(String query) async {
    setState(() {
      _isSearching = true;
      _messages.add(
        Message(text: "Searching academic vault for intent...", isUser: false),
      );
    });

    final results = await _semanticSearchService.search(query);

    setState(() {
      _isSearching = false;
      if (results.isNotEmpty) {
        for (var doc in results) {
          _messages.add(
            Message(
              text: "📚 Found: ${doc.title}\n\nKey finding: ${doc.summary}",
              filePath: doc.path,
              isUser: false,
            ),
          );
        }
      } else {
        _messages.add(
          Message(
            text:
                "No academically relevant documents found for your search intent.",
            isUser: false,
          ),
        );
      }
    });
  }

  void _handleSendMessage() {
    String userText = _controller.text.toLowerCase().trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add(Message(text: userText, isUser: true));
      _controller.clear();
    });

    // STEP 1: Search current chat for AI labels FIRST
    final matchingImage = _messages.firstWhere(
      (msg) => msg.labels.contains(userText),
      orElse: () => Message(text: '', isUser: false),
    );

    if (matchingImage.text.isNotEmpty) {
      setState(() {
        _messages.add(
          Message(
            text: "AI: I found a photo matching '$userText'!",
            filePath: matchingImage.filePath,
            isUser: false,
          ),
        );
      });
    }
    // STEP 2: Only search folders if no AI tag is found
    else {
      _performSemanticSearch(userText);
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: HistoryDrawer(
        historyItems: _searchHistory,
        onFileTap: (path) async => await OpenFilex.open(path),
        onDelete: (index) {
          setState(() => _searchHistory.removeAt(index));
          _saveHistory();
        },
      ),
      appBar: AppBar(
        title: const Text(
          "Fetch AI",
          style: TextStyle(color: Color(0xFFFFB6C1)),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Color(0xFFFFB6C1)),
            onPressed: _searchFiles, // Button to trigger image/PDF picker
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFFFB6C1)),
            onPressed: () => _navigateTo(const SettingsScreen()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isFile = message.filePath != null;

                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.black : Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFB6C1),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // UPDATED: Added logic to show Image preview or PDF icon
                        if (isFile) ...[
                          GestureDetector(
                            onTap: () => OpenFilex.open(message.filePath!),
                            child:
                                message.filePath!.toLowerCase().endsWith('.pdf')
                                ? const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.red,
                                    size: 40,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(message.filePath!),
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          message.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: Color(0xFFFFB6C1)),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask Files...",
                hintStyle: const TextStyle(color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFFB6C1)),
                  onPressed: _handleSendMessage,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFFFB6C1)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// NEW: Data model to store message text and file paths
class Message {
  final String text;
  final String? filePath;
  final bool isUser;
  final List<String> labels; // New: To store what the AI "sees"

  Message({
    required this.text,
    this.filePath,
    required this.isUser,
    this.labels = const [], // Default to empty
  });
}

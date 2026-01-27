import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // Ensure this is imported

// Import your existing screens
import 'history_drawer.dart';
import 'historysearch_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  
  List<Map<String, String>> _SearchHistory = [];
  final TextEditingController _controller = TextEditingController();
  
  // UPDATED: Changed from String to Message object to handle image paths
  final List<Message> _messages = []; 
  bool _isSearching = false;



  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyData = prefs.getString('search_history');
    if (historyData != null) {
      setState(() {
        _SearchHistory = List<Map<String, String>>.from(
          json.decode(historyData).map((item) => Map<String, String>.from(item))
        );
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String historyData = json.encode(_SearchHistory);
    await prefs.setString('search_history', historyData);
  }

  // UPDATED: This function now picks and adds images to the chat
  Future<void> _searchFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'], // Added image formats
    );

    if (result != null) {
      String? pickedPath = result.files.first.path;
      setState(() {
        _messages.add(Message(
          text: "Selected: ${result.files.first.name}",
          filePath: pickedPath,
          isUser: true,
        ));
      });
    }
  }

  Future<void> _searchAllFolders(String query) async {
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) return;

    setState(() {
      _isSearching = true;
      _messages.add(Message(text: "Searching phone for: $query...", isUser: false));
    });

    final root = Directory('/storage/emulated/0/');
    String cleanQuery = query.toLowerCase().trim();
    List<String> foundFiles = [];

    try {
      await for (var entity in root.list(recursive: true, followLinks: false).handleError((e) {})) {
        if (entity.path.contains('/Android') || entity.path.contains('/.')) continue;

        // UPDATED: Now searches for both PDFs and Images
        if (entity is File && (entity.path.toLowerCase().endsWith('.pdf') || 
            entity.path.toLowerCase().endsWith('.jpg') || 
            entity.path.toLowerCase().endsWith('.png'))) {
          
          if (entity.path.toLowerCase().contains(cleanQuery)) {
            foundFiles.add(entity.path);
            break; 
          }
        }
      }

      setState(() {
        _isSearching = false;
        if (foundFiles.isNotEmpty) {
          String filePath = foundFiles.first;
          String fileName = filePath.split('/').last;
          _messages.add(Message(
            text: "Found it! Here is your file: $fileName",
            filePath: filePath,
            isUser: false,
          ));

          if (!_SearchHistory.any((item) => item['path'] == filePath)) {
            _SearchHistory.insert(0, {'name': fileName, 'path': filePath});
            _saveHistory(); 
          }
        } else {
          _messages.add(Message(text: "AI: I couldn't find any file matching '$query'.", isUser: false));
        }
      });
    } catch (e) {
      setState(() => _isSearching = false);
      _messages.add(Message(text: "AI Error: Search failed.", isUser: false));
    }
  }

  void _handleSendMessage() {
    if (_controller.text.trim().isEmpty) return;
    String userText = _controller.text;
    
    setState(() {
      _messages.add(Message(text: userText, isUser: true));
      _controller.clear();
    });

    if (userText.toLowerCase().contains("find") || userText.contains(".")) {
      _searchAllFolders(userText.replaceAll("find", "").trim());
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
        historyItems: _SearchHistory,
        onFileTap: (path) async => await OpenFilex.open(path),
        onDelete: (index) {
          setState(() => _SearchHistory.removeAt(index));
          _saveHistory();
        },
      ),
      appBar: AppBar(
        title: const Text("Fetch AI", style: TextStyle(color: Color(0xFFFFB6C1))),
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
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.black : Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFB6C1), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // UPDATED: Added logic to show Image preview or PDF icon
                        if (isFile) ...[
                          GestureDetector(
                            onTap: () => OpenFilex.open(message.filePath!),
                            child: message.filePath!.toLowerCase().endsWith('.pdf')
                                ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40)
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(File(message.filePath!), height: 150, fit: BoxFit.cover),
                                  ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(message.text, style: const TextStyle(color: Colors.white)),
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
    this.labels = const [] // Default to empty
  });
}
  
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

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
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  // Logic to search for PDF files in the Downloads folder
  Future<void> _autoSearchFilesV2(String query) async {
    var status = await Permission.manageExternalStorage.request();
    
    if (status.isGranted) {
      setState(() {
        _messages.add("Searching for: $query...");
      });

      try {
        // Accessing the public Downloads directory
        final directory = Directory('/storage/emulated/0/Download');
        
        if (await directory.exists()) {
          final List<FileSystemEntity> entities = directory.listSync();
          List<String> foundFiles = [];

          for (var entity in entities) {
            // Check for PDF extension
            if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
              String fileName = entity.path.split('/').last;
              if (fileName.toLowerCase().contains(query.toLowerCase())) {
                foundFiles.add(fileName);
              }
            }
          }

          setState(() {
            if (foundFiles.isNotEmpty) {
              _messages.add("Found it! Here is your file: ${foundFiles.first}");
            } else {
              _messages.add("AI: No matching PDFs found in Downloads.");
            }
          });
        }
      } catch (e) {
        setState(() => _messages.add("Error: $e"));
      }
    } else {
      setState(() => _messages.add("Permission denied. Check phone settings."));
    }
  }

  void _handleSendMessage() {
    if (_controller.text.trim().isEmpty) return;
    String userText = _controller.text;
    
    setState(() {
      _messages.add(userText);
      _controller.clear();
    });

    // Auto-trigger search if query looks like a file request
    if (userText.toLowerCase().contains("find") || userText.contains(".pdf")) {
      _autoSearchFilesV2(userText.replaceAll("find", "").trim());
    }
  }

  // Navigation logic for your other three screens
  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const HistoryDrawer(), // Connected to History Screen
      appBar: AppBar(
        title: const Text("Fetch AI", style: TextStyle(color: Color(0xFFFFB6C1))),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFFB6C1)),
            onPressed: () => _navigateTo(const HistorySearchScreen()), // Connected to Search
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFFFB6C1)),
            onPressed: () => _navigateTo(const SettingsScreen()), // Connected to Settings
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
                bool isFileResponse = _messages[index].contains("Found it!");

                return Align(
                  alignment: isFileResponse ? Alignment.centerLeft : Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () async {
                      if (isFileResponse) {
                        // Extract filename and open from Downloads
                        String fileName = _messages[index].split(": ").last.trim();
                        String filePath = '/storage/emulated/0/Download/$fileName';
                        await OpenFilex.open(filePath);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isFileResponse ? Colors.grey[900] : Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFB6C1), width: 1.5),
                      ),
                      child: Text(
                        _messages[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input Bar
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
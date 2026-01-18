import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required to convert the list to a string

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
  // Inside _HomeScreenState
  List<Map<String, String>> _SearchHistory = []; // Stores { 'name': 'A.pdf', 'path': '...' }
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  bool _isSearching = false; // Add this line

  @override
void initState() {
  super.initState();
  _loadHistory(); // Load history as soon as the app starts
}

// 1. Load history from phone memory
Future<void> _loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final String? historyData = prefs.getString('search_history');
  
  if (historyData != null) {
    setState(() {
      // Convert the saved String back into a List
      _SearchHistory = List<Map<String, String>>.from(
        json.decode(historyData).map((item) => Map<String, String>.from(item))
      );
    });
  }
}

// 2. Save history to phone memory
Future<void> _saveHistory() async {
  final prefs = await SharedPreferences.getInstance();
  // Convert the List into a String to save it
  String historyData = json.encode(_SearchHistory);
  await prefs.setString('search_history', historyData);
}

  // Logic to search for PDF files in the Downloads folder
  Future<void> _searchAllFolders(String query) async {
  var status = await Permission.manageExternalStorage.request();
  
  if (status.isGranted) {
    setState(() {
      _isSearching = true; // Turn on spinner
      _messages.add("Searching phone for: $query...");
    });

    final root = Directory('/storage/emulated/0/');
    List<String> foundFiles = [];

    try {
      // Use .list() stream to keep the UI alive during the heavy scan
      await for (var entity in root.list(recursive: true, followLinks: false).handleError((e) {
        // This ignores "Access Denied" errors so the search continues
        debugPrint("Skipping restricted folder: $e");
      })) {
        
        // SPEED OPTIMIZATION: Skip system folders that definitely don't have your PDFs
        if (entity.path.contains('/Android') || entity.path.contains('/.')) continue;

        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          String fileName = entity.path.split('/').last;
          
          // Use trim() to avoid issues with accidental spaces in user input
          if (fileName.toLowerCase().contains(query.toLowerCase().trim())) {
            foundFiles.add(entity.path);
            // We found a match, so we can stop searching now to save time
            break; 
          }
        }
      }

      setState(() {
        _isSearching = false; // Turn off spinner
        if (foundFiles.isNotEmpty) {
          String filePath = foundFiles.first;
          String fileName = filePath.split('/').last;
          _messages.add("Found it! Here is your file: $fileName");

          if (!_SearchHistory.any((item) => item['path'] == filePath)) {
            _SearchHistory.insert(0, {'name': fileName, 'path': filePath});
            _saveHistory(); 
          }
        } else {
          _messages.add("AI: I searched everywhere, but I couldn't find a PDF named '$query'.");
        }
      });
    } catch (e) {
      setState(() => _isSearching = false);
      _messages.add("AI Error: Something went wrong during the search.");
    }
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
  _searchAllFolders(userText.replaceAll("find", "").trim()); // Updated name
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
      drawer: HistoryDrawer(
  historyItems: _SearchHistory,
  onFileTap: (path) async {
    await OpenFilex.open(path);
    },
    onDelete: (index) {
    setState(() {
      _SearchHistory.removeAt(index);
    });
  _saveHistory();
  },
),
 // Connected to History Screen
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
                      // Look up the path from your history list using the filename
                        String fileName = _messages[index].split(": ").last.trim();
                        final historyItem = _SearchHistory.firstWhere((item) => item['name'] == fileName);
    
                        await OpenFilex.open(historyItem['path']!); // Opens from the specific folder found
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
                     child: Row(
                      mainAxisSize: MainAxisSize.min, // Prevents the bubble from stretching too far
                        children: [
                          if (isFileResponse) ...[
                            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                            const SizedBox(width: 10),
                          ],
                          Flexible( // Wraps text if the filename is very long
                    child: Text(
                      _messages[index],
                        style: const TextStyle(color: Colors.white),
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
          if (_isSearching)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFB6C1),
          ),
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
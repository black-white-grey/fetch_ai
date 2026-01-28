import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Ensure this is imported

// Import your existing screens
import 'history_drawer.dart';
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
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
  );

  if (result != null) {
    String path = result.files.first.path!;
    List<String> detectedLabels = [];

    // If it's an image, let the AI "see" it
    if (!path.toLowerCase().endsWith('.pdf')) {
      detectedLabels = await _getImageLabels(path);
      print("AI Detected Labels: $detectedLabels");
    }

    setState(() {
  _messages.add(Message(
    text: "Picked: ${result.files.first.name}",
    filePath: path,
    isUser: true,
    labels: detectedLabels, // Use the new name here
  ));
});
  }
}

  Future<List<String>> _getImageLabels(String path) async {
  final inputImage = InputImage.fromFilePath(path);
  final imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
  
  final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
  List<String> labelTexts = labels.map((label) => label.label.toLowerCase()).toList();
  
  imageLabeler.close();
  return labelTexts;
}

  Future<void> _searchAllFolders(String query) async {
  var status = await Permission.manageExternalStorage.request();
  if (!status.isGranted) return;
  

  setState(() {
    _isSearching = true;
    _messages.add(Message(text: "AI is scanning your phone...", isUser: false));
  });

  final root = Directory('/storage/emulated/0/');
  List<String> allFilePaths = []; // FIX: Define allFilePaths here

  try {
    await for (var entity in root.list(recursive: true).handleError((e) {})) {
      if (entity is File && !entity.path.contains('/Android')) {
        allFilePaths.add(entity.path); 

        // Inside the root.list loop
if (entity is File && !entity.path.contains('/Android')) {
  allFilePaths.add(entity.path); 
}

// After the loop finishes, check if we found anything
print("Total files found for AI to scan: ${allFilePaths.length}"); 
if (allFilePaths.isEmpty) {
  print("Error: No files found. Check your storage permissions!");
}
      }
    }

    // FIX: Pass 'query' (the parameter name) to the Gemini function
    String bestMatchPath = await _askGeminiToFindFile(allFilePaths, query);

    setState(() {
      _isSearching = false;
      if (bestMatchPath != "Not found") {
        _messages.add(Message(
          text: "AI found: ${bestMatchPath.split('/').last}",
          filePath: bestMatchPath,
          isUser: false,
        ));
      } else {
        _messages.add(Message(text: "AI: I couldn't find a match.", isUser: false));
      }
    });
  } catch (e) {
    setState(() => _isSearching = false);
  }
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
      _messages.add(Message(
        text: "AI: I found a photo matching '$userText'!",
        filePath: matchingImage.filePath,
        isUser: false,
      ));
    });
  } 
  // STEP 2: Only search folders if no AI tag is found
  else {
    _searchAllFolders(userText);
  }
}
  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // Check line 117. It must match this name exactly:
Future<String> _askGeminiToFindFile(List<String> paths, String query) async {
  // Use your real API Key from Google AI Studio here
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: 'YOUR_API_KEY'); 
  
  // Combine all instructions into ONE prompt variable
  final String promptInstructions = """
    You are a file assistant. 
    User is looking for: '$query'. 
    From this list of local files: ${paths.take(150).toList()} 

    Instructions: 
    1. Return ONLY the absolute file path of the best match. 
    2. Do not include any text, code blocks, or explanations. 
    3. If no match exists, return 'Not found'.
  """;

  final response = await model.generateContent([Content.text(promptInstructions)]);
  return response.text?.trim() ?? "Not found";
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
  
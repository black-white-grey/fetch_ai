import 'package:flutter/material.dart';
import 'history_drawer.dart';
import 'home_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:open_filex/open_filex.dart';// Import to allow navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = []; // Stores your chat history
  bool _isTyping = false;

  // Function for the smooth slide transition from the left
  Route _createLeftToRightRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const HistoryDrawer(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); // Starts from the left off-screen
        const end = Offset.zero;
        const curve = Curves.easeInOutQuart;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Inside _HomeScreenState in home_screen.dart

Future<void> _autoSearchFiles(String query) async {
  setState(() {
    _messages.add("Analyzing your request: '$query'...");
  });

  // 1. Simple Keyword Parsing
  DateTime now = DateTime.now();
  DateTime? startTime;

  if (query.toLowerCase().contains("week")) {
    startTime = now.subtract(const Duration(days: 7));
  } else if (query.toLowerCase().contains("month")) {
    startTime = now.subtract(const Duration(days: 30));
  }

  if (startTime == null) {
    setState(() {
      _messages.add("I'm not sure which time frame you mean. Try 'this week'.");
    });
    return;
  }

  // 2. Access the File Manager (Internal Storage)
  try {
    // We search the Documents directory for safety
    final directory = await getApplicationDocumentsDirectory(); 
    final List<FileSystemEntity> files = directory.listSync();
    
    List<String> foundFiles = [];

    for (var file in files) {
      if (file is File && file.path.endsWith('.pdf')) {
        DateTime fileDate = file.lastModifiedSync();
        // Check if file date is within the requested range
        if (fileDate.isAfter(startTime)) {
          foundFiles.add(file.path.split('/').last);
        }
      }
    }

    // 3. Send the result back to UI
    setState(() {
      if (foundFiles.isNotEmpty) {
        _messages.add("I found ${foundFiles.length} PDF(s) from that period:");
        for (var fileName in foundFiles) {
          _messages.add("📄 $fileName");
        }
      } else {
        _messages.add("I couldn't find any PDFs from that timeframe in your documents.");
      }
    });
  } catch (e) {
    setState(() {
      _messages.add("Error accessing file manager: $e");
    });
  }
}
void _handleSendMessage() async {
  if (_controller.text.isNotEmpty) {
    String query = _controller.text;
    
    setState(() {
      _messages.add(query); // Add user query to UI
      _controller.clear();
      _isTyping = false;
    });

    // Call the backend/AI service
    await _searchForFile(query);
  }
}

Future<void> _searchForFile(String query) async {
  // 1. Show a loading indicator in the chat
  setState(() {
    _messages.add("Searching for: $query...");
  });

  // 2. Simulated Backend/AI Logic
  // In a real app, use the 'http' package to call your API
  try {
    // Example: var response = await http.post(Uri.parse('YOUR_AI_BACKEND_URL'), body: {'query': query});
    
    // For now, let's simulate a successful find:
    await Future.delayed(const Duration(seconds: 2)); // Simulate network lag
    
    setState(() {
      _messages.add("Found it! Here is your file: $query.pdf");
    });
  } catch (e) {
    setState(() {
      _messages.add("Sorry, I couldn't find that file.");
    });
  }
}

Future<void> _autoSearchFilesV2(String query) async {
  // 1. Request storage permission
  var status = await Permission.storage.request();
  
  if (status.isGranted) {
    setState(() {
      _messages.add("AI: Searching your files for '$query'...");
    });

    try {
      // 2. Define and find the files
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> entities = directory.listSync();
      
      // Define foundFiles HERE so the code below can see it
      List<String> foundFiles = [];

      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          // Add your time-filtering logic here if needed
          foundFiles.add(entity.path.split('/').last);
        }
      }

      // 3. Now check if foundFiles is empty or not
      setState(() {
        if (foundFiles.isNotEmpty) {
          _messages.add("AI: I found these files for you:");
          for (var fileName in foundFiles) {
            _messages.add("FILE: $fileName");
          }
        } else {
          _messages.add("AI: Sorry, I couldn't find any PDFs matching that.");
        }
      });
    } catch (e) {
      setState(() {
        _messages.add("AI: Error accessing files: $e");
      });
    }
  } else {
    setState(() {
      _messages.add("AI: Permission denied. I cannot search files.");
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Menu Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(_createLeftToRightRoute());
                    },
                  ),
                ),
              ),
            ),

            // 2. Chat Message Display Area
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Search Files',
                        style: TextStyle(fontSize: 24, color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
  return Align(
    alignment: Alignment.centerRight,
    child: GestureDetector(
      onTap: () async {
  if (_messages[index].startsWith("FILE:")) {
    String fileName = _messages[index].replaceFirst("FILE: ", "");
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/$fileName';

    // This uses the package you just downgraded/installed
    await OpenFilex.open(filePath); 
  }
},
      
      // MOVE THE CONTAINER HERE - inside the GestureDetector
      child: Container( 
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFB6C1), 
            width: 1.5,
          ),
        ),
        child: Text(
          _messages[index],
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}
                  )
            ),

            // 3. Bottom Input Section (Typing area)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (val) {
                          setState(() {
                            _isTyping = val.isNotEmpty;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Ask Files...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isTyping ? Icons.send : Icons.mic_none,
                        color: Colors.white,
                      ),
                      onPressed: _handleSendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
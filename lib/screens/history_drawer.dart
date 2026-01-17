import 'package:flutter/material.dart';
import 'historysearch_screen.dart'; //
import 'settings_screen.dart'; //

class HistoryDrawer extends StatelessWidget {
  // Define the parameters the drawer will receive
  final List<Map<String, String>> historyItems;
  final Function(String) onFileTap;

  // Add them to the constructor
  const HistoryDrawer({
    super.key, 
    required this.historyItems, 
    required this.onFileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: SafeArea(
        child: Column(
          children: [
            // Your existing top bar code (icons and user name) remains here...
            
            const Divider(color: Colors.white24),

            Expanded(
              child: historyItems.isEmpty
                  ? const Center(
                      child: Text("No history yet", style: TextStyle(color: Colors.white24)),
                    )
                  : ListView.builder(
                      itemCount: historyItems.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text(
                            historyItems[index]['name'] ?? 'Unknown File',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            // Close the drawer and open the file
                            Navigator.pop(context);
                            onFileTap(historyItems[index]['path']!);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  _iconWithBorder(Icons.settings, () => Navigator.of(context).push(_createSmoothRoute(const SettingsScreen()))), //
                  const SizedBox(width: 10),
                  const Text("User name", style: TextStyle(fontSize: 18)),
                  const Spacer(),
                  _iconWithBorder(Icons.search, () => Navigator.of(context).push(_createSmoothRoute(const HistorySearchScreen()))), //
                ],
              ),
            ),
            const Expanded(child: Center(child: Text("No history yet", style: TextStyle(color: Colors.white24)))),
          ],
        ),
      ),
    );
  }

  Widget _iconWithBorder(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFB6C1), width: 1.5)),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Route _createSmoothRoute(Widget screen) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Slides in from the right
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

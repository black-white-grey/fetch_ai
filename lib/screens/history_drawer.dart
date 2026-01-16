import 'package:flutter/material.dart';
import 'historysearch_screen.dart';

// IMPORTANT: Name this class 'HistoryDrawer' to match your home_screen.dart
class HistoryDrawer extends StatelessWidget {
  const HistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  _iconWithBorder(Icons.settings, () {
                    // Navigate to settings_screen.dart later
                  }),
                  const SizedBox(width: 12),
                  const Text(
                    "User name",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const Spacer(),
                  _iconWithBorder(Icons.search, () {
                    // Smooth Transition to History Search Screen
                    Navigator.of(context).push(_createSearchRoute());
                  }),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text("No history yet", style: TextStyle(color: Colors.white24)),
              ),
            ),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFB6C1), width: 1.5),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Route _createSearchRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const HistorySearchScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Slides up from bottom
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
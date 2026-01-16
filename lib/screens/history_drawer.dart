import 'package:flutter/material.dart';
import 'historysearch_screen.dart'; //
import 'settings_screen.dart'; //

class HistoryDrawer extends StatelessWidget {
  const HistoryDrawer({super.key});

  // Smooth slide-up transition
  Route _createSmoothRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Slides up from bottom
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutQuart));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
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
}
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color babyPink = Color(0xFFFFB6C1);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close Button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),

              // --- Account Section ---
              _sectionHeader("Account", babyPink),
              _settingsInput("Username", babyPink),
              _settingsInput("Email", babyPink),
              _simpleTextButton("Clear History"),
              _simpleTextButton("logout"),
              _simpleTextButton("Update version"),

              const Divider(color: Colors.white12, height: 40),

              // --- Appearance Section ---
              _sectionHeader("Appearance", babyPink),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Night mode", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Switch(
                    value: true, 
                    onChanged: (val) {}, 
                    activeColor: babyPink,
                  ),
                ],
              ),
              _simpleTextButton("Theme"),

              const Divider(color: Colors.white12, height: 40),

              // --- More Section ---
              _sectionHeader("More", babyPink),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(color: color.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _settingsInput(String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1),
          ),
        ),
      ],
    );
  }

  Widget _simpleTextButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
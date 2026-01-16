import 'package:flutter/material.dart';

class HistoryDrawer extends StatelessWidget {
  const HistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildHeader(context),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _historyTile("name of file searched 2 hours ago", "2hr"),
                _historyTile("name of file searched 1 week ago", "1w"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          _iconWithBorder(Icons.settings),
          const SizedBox(width: 10),
          const Text("User name", style: TextStyle(fontSize: 18)),
          const Spacer(),
          _iconWithBorder(Icons.search),
        ],
      ),
    );
  }

  Widget _iconWithBorder(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
      ),
      child: Icon(icon, size: 20, color: Colors.white),
    );
  }

  Widget _historyTile(String title, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
          trailing: const Icon(Icons.more_vert, size: 20, color: Colors.white),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const Divider(color: Color(0xFFFFB6C1), thickness: 0.5, height: 1),
      ],
    );
  }
}
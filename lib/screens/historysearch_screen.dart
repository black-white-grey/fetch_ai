import 'package:flutter/material.dart';

class HistorySearchScreen extends StatefulWidget {
  const HistorySearchScreen({super.key});

  @override
  State<HistorySearchScreen> createState() => _HistorySearchScreenState();
}

class _HistorySearchScreenState extends State<HistorySearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFFFB6C1), width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search history files.....',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Icon(Icons.search, size: 100, color: Colors.white10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
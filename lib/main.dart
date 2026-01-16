import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Ensure this path is correct

void main() => runApp(const FetchAIApp());

class FetchAIApp extends StatelessWidget {
  const FetchAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const HomeScreen(), // This will now link to your home_screen.dart
    );
  }
}
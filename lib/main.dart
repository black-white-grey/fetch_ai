import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart'; 
// Ensure this path is correct';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //
  
  // This line connects your code to the google-services.json config
  await Firebase.initializeApp(); 
  
  runApp(const MyApp());
}

class FetchAIApp extends StatelessWidget {
  const FetchAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const HomeScreen(), // This will now link to your home_screen.dart
    );
  }
}

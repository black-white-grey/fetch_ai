import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; //
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
 // Ensure this path matches your folder structure

void main() async {
  // 1. Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized(); 

  // 2. Initialize Firebase using the google-services.json config
  await Firebase.initializeApp(); 

  // 3. Start the application
  runApp(const FetchAIApp()); //
}

class FetchAIApp extends StatelessWidget {
  const FetchAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fetch AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFB6C1), // Your theme pink
        scaffoldBackgroundColor: Colors.black,
      ),
      // Change this line in your FetchAIApp class in main.dart:
      home: const LoginScreen(), // This directs to your chat UI
    );
  }
}
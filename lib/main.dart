import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; //

import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
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
        primaryColor: const Color(0xFFFFB6C1), // Academic Pastel highlight
        scaffoldBackgroundColor: const Color(
          0xFF1E1E1E,
        ), // Deep muted dark mode
      ),
      // Change this line in your FetchAIApp class in main.dart:
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), //
        builder: (context, snapshot) {
          // If the snapshot has user data, they are logged in
          if (snapshot.hasData) {
            return const MainNavigationScreen();
          }
          // Otherwise, send them to login
          return const LoginScreen();
        },
      ),
    );
  } // This directs to your chat UI
}

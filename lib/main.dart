// ignore_for_file: unnecessary_import

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Global Flutter Error Handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("Global Flutter Error: ${details.exception}");
  };

  // 2. Global Asynchronous Error Handling
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint("Global Async Error: $error");
    return true;
  };

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCG2wyHZrGQELklQTDeBhd2s-Yn-xyo9Uc",
        appId: "1:906061960215:android:01b34be5aa915ab3cb3852",
        messagingSenderId: "906061960215",
        projectId: "cmsy-cb0c5",
        storageBucket: "cmsy-cb0c5.firebasestorage.app",
      ),
    );

    // Fix for connectivity issues (QUIC protocol errors)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      webExperimentalForceLongPolling: true,
    );

    debugPrint("Firebase Initialized Successfully");
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College App',
      debugShowCheckedModeBanner: false,
      // 3. Custom Error Widget for UI crashes
      builder: (context, child) {
        ErrorWidget.builder = (details) {
          return Material(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details.exception.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          );
        };
        return child!;
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo/Violet
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFEC4899), // Pink for accents
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

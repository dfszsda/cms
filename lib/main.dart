import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with corrected credentials from google-services.json
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCG2wyHZrGQELklQTDeBhd2s-Yn-xyo9Uc",
        appId: "1:906061960215:android:01b34be5aa915ab3cb3852",
        messagingSenderId: "906061960215",
        projectId: "cmsy-cb0c5",
        storageBucket: "cmsy-cb0c5.firebasestorage.app",
      ),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

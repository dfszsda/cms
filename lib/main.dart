import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with your options
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBPwHkKttJBd6AZRwiXwI9A_WD9avfFbho",
      authDomain: "cmsy-cb0c5.firebaseapp.com",
      projectId: "cmsy-cb0c5",
      storageBucket: "cmsy-cb0c5.firebasestorage.app",
      messagingSenderId: "906061960215",
      appId: "1:906061960215:web:2a1dec9f44e28a0bcb3852",
      measurementId: "G-NRHX7N7PFJ",
    ),
  );

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

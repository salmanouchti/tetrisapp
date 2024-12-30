import 'package:flutter/material.dart';
import 'package:tetrisapp/board.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCQheWzGJ0a8GT3jdC_VRhUSQv80qY3RH4",
      appId: "1:181854862346:android:6ce0e8ff7a1244174c73f3",
      messagingSenderId: "181854862346", // Corrected numeric ID
      projectId: "tetrisapp-8c64d",
    ),
  ); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/board': (context) => const GameBoard(),
        '/auth': (context) => const AuthPage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const GameBoard(); // User is logged in
          } else {
            return const AuthPage(); // User is not logged in
          }
        },
      ),
    );
  }
}

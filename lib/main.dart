import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate( androidProvider: AndroidProvider.debug, );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbería App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.getFont('Google Sans Flex').fontFamily,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
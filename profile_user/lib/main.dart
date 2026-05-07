import 'package:flutter/material.dart';
import 'screens/profile_page.dart'; // Import halaman profil

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile App',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFC6620C),
      ),
      // Aplikasi dimulai dari ProfilePage
      home: const ProfilePage(),
    );
  }
}

\\\\\\\\\\\\

name: profile_user
description: "A new Flutter project."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
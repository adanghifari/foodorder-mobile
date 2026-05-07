import 'package:flutter/material.dart';
// Pastikan nama file import di bawah ini sesuai dengan nama file yang kamu simpan
import 'menu_page.dart'; 

void main() {
  runApp(const KedaiKlikApp());
}

class KedaiKlikApp extends StatelessWidget {
  const KedaiKlikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KedaiKlik',
      theme: ThemeData(
        // Menggunakan font default sistem atau Plus Jakarta Sans jika sudah dikonfigurasi di pubspec.yaml
        fontFamily: 'Plus Jakarta Sans', 
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8641E),
          primary: const Color(0xFFC8641E),
        ),
      ),
      // Jika kamu punya LandingPage, ganti MenuPage() menjadi LandingPage()
      home: const MenuPage(), 
    );
  }
}
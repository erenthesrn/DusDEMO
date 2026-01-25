// lib/main.dart
import 'package:flutter/material.dart';
// LoginPage'i tanıması için bu import gerekli:
import 'screens/login_page.dart'; 

void main() {
  runApp(const DusApp());
}

class DusApp extends StatelessWidget {
  const DusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DUS Asistanı',
      debugShowCheckedModeBanner: false,
      // TEMA AYARLARI
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1), // Koyu Mavi
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF00BFA5), // Turkuaz
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      // Uygulama LoginPage ile başlar (Burada const olmamasına dikkat ettik)
      home: const LoginPage(), 
    );
  }
}
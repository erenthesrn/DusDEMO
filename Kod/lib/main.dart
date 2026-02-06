// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// --- SERVİS İMPORTLARI ---
import 'services/focus_service.dart';
import 'services/theme_provider.dart'; // Tema sağlayıcısını ekledik

// Sayfalar
import 'screens/home_screen.dart';
import 'screens/login_page.dart';
import 'package:dus_app_1/screens/blog_screen.dart';
import 'package:dus_app_1/screens/quiz_screen.dart';

// --- 1. ADIM: GLOBAL NAVIGATOR KEY ---
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- PLATFORM AYARLARI ---
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDNxUY3kYnZJNl-TtxCkCjSn94ubg97dgc",
        appId: "1:272729938344:web:6e766b4cb0c63e94f8259d",
        authDomain: "dusapp-17b00.firebaseapp.com",
        messagingSenderId: "272729938344",
        projectId: "dusapp-17b00",
        storageBucket: "dusapp-17b00.firebasestorage.app",
        measurementId: "G-9Z19HY8QBF"
      ),
    );
  } 
  else if (defaultTargetPlatform == TargetPlatform.iOS) {
    await Firebase.initializeApp();
  } 
  else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCSEnLiJqIOIE0FxXNJNNmiNIWM85OFVKM",
        appId: "1:272729938344:android:f8312320eb7df19cf8259d",
        messagingSenderId: "272729938344",
        projectId: "dusapp-17b00",
      ),
    );
  }

  // --- FOCUS SERVICE BAŞLATMA ---
  FocusService.instance; 

  runApp(const DusApp());
}

class DusApp extends StatelessWidget {
  const DusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- LİSTENABLBUİLDER: Tema değişimini tüm uygulamada anlık tetikler ---
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, 
          title: 'DUS Asistanı',
          debugShowCheckedModeBanner: false,
          
          // --- TEMA MODU SEÇİMİ ---
          themeMode: ThemeProvider.instance.themeMode,

          // --- 1. AYDINLIK TEMA AYARLARI ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFF0D47A1),
            scaffoldBackgroundColor: const Color(0xFFF5F9FF),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              primary: const Color(0xFF0D47A1),
              secondary: const Color(0xFF00BFA5),
              brightness: Brightness.light,
            ),
            inputDecorationTheme: _buildInputDecorationTheme(Brightness.light),
            elevatedButtonTheme: _buildElevatedButtonTheme(),
          ),

          // --- 2. KARANLIK TEMA AYARLARI ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF0D47A1),
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              primary: const Color(0xFF0D47A1),
              secondary: const Color(0xFF00BFA5),
              brightness: Brightness.dark,
            ),
            inputDecorationTheme: _buildInputDecorationTheme(Brightness.dark),
            elevatedButtonTheme: _buildElevatedButtonTheme(),
          ),

          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return const HomeScreen();
              }
              return const LoginPage();
            },
          ),
        );
      }
    );
  }

  // Ortak Tasarım Metodları (Kod tekrarını önlemek için)
  InputDecorationTheme _buildInputDecorationTheme(Brightness brightness) {
    return InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light ? Colors.grey[100] : Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[800]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
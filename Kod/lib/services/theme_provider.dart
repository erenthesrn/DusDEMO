// lib/services/theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Singleton yapısı
  static final ThemeProvider _instance = ThemeProvider._internal();
  static ThemeProvider get instance => _instance;
  ThemeProvider._internal();

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Tüm uygulamaya haber ver
  }
}
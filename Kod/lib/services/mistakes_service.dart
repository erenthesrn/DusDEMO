// lib/services/mistakes_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';

class MistakesService {
  static const String _storageKey = "saved_mistakes_v1";

  // --- YANLIŞLARI EKLE ---
  static Future<void> addMistakes(List<Map<String, dynamic>> newMistakes) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Mevcut yanlışları çek
    List<Map<String, dynamic>> currentMistakes = await getMistakes();

    // 2. Yeni yanlışları ekle (Aynı soru varsa tekrar ekleme kontrolü yapılabilir)
    for (var mistake in newMistakes) {
      // Basit bir kontrol: Aynı soru ID'si ve aynı ders ismi varsa ekleme
      bool exists = currentMistakes.any((m) => 
          m['id'] == mistake['id'] && m['subject'] == mistake['subject']);
      
      if (!exists) {
        currentMistakes.add(mistake);
      }
    }

    // 3. Güncel listeyi kaydet
    await prefs.setString(_storageKey, json.encode(currentMistakes));
  }

  // --- TÜM YANLIŞLARI GETİR ---
  static Future<List<Map<String, dynamic>>> getMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_storageKey);
    
    if (data != null) {
      return List<Map<String, dynamic>>.from(json.decode(data));
    }
    return [];
  }

  // --- YANLIŞI SİL (Doğrusunu öğrendim butonu için) ---
  static Future<void> removeMistake(int questionId, String subject) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> mistakes = await getMistakes();
    
    mistakes.removeWhere((m) => m['id'] == questionId && m['subject'] == subject);
    
    await prefs.setString(_storageKey, json.encode(mistakes));
  }
}
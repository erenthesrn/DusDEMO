import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MistakesService {
  static const String _storageKey = 'user_mistakes';

  static Future<List<Map<String, dynamic>>> getMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mistakesString = prefs.getString(_storageKey);
    if (mistakesString != null) {
      return List<Map<String, dynamic>>.from(json.decode(mistakesString));
    }
    return [];
  }

  // --- EKLENECEK KISIM 1: Toplu Ekleme ---
  static Future<void> addMistakes(List<Map<String, dynamic>> newMistakes) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> currentMistakes = await getMistakes();

    for (var mistake in newMistakes) {
      // Varsa eskisini çıkar (güncelleyip sona ekleyeceğiz)
      currentMistakes.removeWhere((item) => 
          item['id'] == mistake['id'] && item['subject'] == mistake['subject']);
      currentMistakes.add(mistake);
    }
    await prefs.setString(_storageKey, json.encode(currentMistakes));
  }

  // --- EKLENECEK KISIM 2: Toplu Silme ---
  static Future<void> removeMistakeList(List<Map<String, dynamic>> itemsToRemove) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> currentMistakes = await getMistakes();

    for (var item in itemsToRemove) {
      currentMistakes.removeWhere((m) => 
          m['id'] == item['id'] && m['subject'] == item['subject']);
    }
    await prefs.setString(_storageKey, json.encode(currentMistakes));
  }

  // Tekli silme (Zaten varsa kalabilir)
  static Future<void> removeMistake(int id, String subject) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> currentMistakes = await getMistakes();
    currentMistakes.removeWhere((item) => item['id'] == id && item['subject'] == subject);
    await prefs.setString(_storageKey, json.encode(currentMistakes));
  }
}
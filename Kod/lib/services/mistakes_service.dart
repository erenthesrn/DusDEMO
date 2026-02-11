import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MistakesService {
  static const String _localKey = 'user_mistakes';

  // 🔥 1. ADIM: YEREL VERİYİ BULUTA TAŞIMA (MIGRATION)
  // Bu fonksiyonu uygulamanın açılışında (örneğin Home veya Splash ekranında) bir kez çağıracağız.
  static Future<void> syncLocalToFirebase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? localString = prefs.getString(_localKey);

    if (localString != null) {
      List<dynamic> localList = json.decode(localString);
      if (localList.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mistakes');

      for (var item in localList) {
        // Her yanlış soru için benzersiz bir ID oluşturuyoruz (soruId_dersAdi)
        String docId = "${item['id']}_${item['subject']}".replaceAll(" ", "_");
        var docRef = collectionRef.doc(docId);
        
        // Veriyi Firebase formatına uygun hale getirip ekliyoruz
        batch.set(docRef, {
          ...item,
          'syncedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });
      }

      await batch.commit();
      
      // Başarılı olursa yerel veriyi temizle
      await prefs.remove(_localKey);
      print("✅ Yerel 'Yanlışlarım' verisi Firebase'e taşındı ve cihazdan silindi.");
    }
  }

  // --- GETİRME (FIREBASE) ---
  static Future<List<Map<String, dynamic>>> getMistakes() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mistakes')
          .orderBy('date', descending: true) // En yeni en üstte
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Hata (Get Mistakes): $e");
      return [];
    }
  }

  // --- EKLEME (FIREBASE) ---
  static Future<void> addMistakes(List<Map<String, dynamic>> newMistakes) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mistakes');

    for (var mistake in newMistakes) {
      // Soru ID ve Ders adı ile unique bir key oluşturuyoruz ki aynı soruyu 2 kere eklemesin
      String docId = "${mistake['id']}_${mistake['subject']}".replaceAll(" ", "_");
      var docRef = collectionRef.doc(docId);

      batch.set(docRef, {
        ...mistake,
        'userId': user.uid,
        'addedAt': FieldValue.serverTimestamp(), // Ne zaman eklendi?
      });
    }

    await batch.commit();
  }

  // --- TEKLİ SİLME (FIREBASE) ---
  static Future<void> removeMistake(int id, String subject) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String docId = "${id}_$subject".replaceAll(" ", "_");
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mistakes')
        .doc(docId)
        .delete();
  }

  // --- 🔥 EKSİK OLAN KISIM: TOPLU SİLME (FIREBASE) ---
  static Future<void> removeMistakeList(List<Map<String, dynamic>> itemsToRemove) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mistakes');

    for (var item in itemsToRemove) {
      // Silinecek doküman ID'sini oluştur
      String docId = "${item['id']}_${item['subject']}".replaceAll(" ", "_");
      batch.delete(collection.doc(docId));
    }

    // İşlemi onayla
    await batch.commit();
  }
}
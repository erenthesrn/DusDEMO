import 'dart:convert';
import 'package:flutter/services.dart'; // rootBundle için
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionUploader {
  
  // Bu fonksiyonu istediğin kadar çalıştırabilirsin.
  // Var olanı günceller, olmayanı ekler.
  static Future<void> uploadQuestions() async {
    final firestore = FirebaseFirestore.instance;
    
    // JSON dosya isimlerin (Assets/data/ altındakiler)
    final files = [
      'anatomi', 
      'biyokimya', 
      'biyoloji',
      'cerrahi', 
      'endo',
      'farma',
      'fizyoloji',
      'histoloji',
      'mikrobiyo',
      'orto',
      'patoloji',
      'pedo',
      'perio', 
      'protetik',
      'radyoloji',
      'resto',

      // Diğer dersleri buraya ekle...
    ];

    print("Yükleme başladı... 🚀");

    for (String lesson in files) {
      try {
        // 1. JSON Oku
        String jsonString = await rootBundle.loadString('Assets/data/$lesson.json');
        var jsonData = jsonDecode(jsonString);
        
        List<dynamic> tests = [];
        
        // JSON yapısı bazen Map {"Anatomi": []} bazen direkt List [] olabiliyor diye kontrol:
        if (jsonData is Map) {
          tests = jsonData.values.first; // Map ise ilk değer listedir
        } else if (jsonData is List) {
          tests = jsonData;
        }

        // 2. Batch (Toplu İşlem) Hazırla
        WriteBatch batch = firestore.batch();
        int counter = 0; // Batch limiti (500) için sayaç

        for (var test in tests) {
          int testNo = test['testNo'];
          List<dynamic> questions = test['questions'];

          for (int i = 0; i < questions.length; i++) {
            var q = questions[i];
            
            // 🔥 KRİTİK NOKTA: ID'yi biz belirliyoruz.
            // Örn: anatomi_1_0 (Anatomi, 1. Test, 0. Soru)
            String docId = "${lesson.toLowerCase()}_${testNo}_$i";
            
            DocumentReference docRef = firestore.collection('questions').doc(docId);
            
            // Veriyi hazırla
            Map<String, dynamic> data = {
              'topic': lesson, // Dosya adını konu olarak kullanıyoruz
              'testNo': testNo,
              'questionIndex': i, // Sırasını kaybetmemek için
              'question': q['question'],
              'options': q['options'],
              'correctIndex': q['correctOption'],
              'explanation': q['explanation'] ?? "",
              // İleride "image_url" falan eklemek istersen JSON'a koyup buraya eklemen yeterli
            };

            // set(data) -> Varsa ezer, yoksa yazar.
            batch.set(docRef, data); 

            counter++;
            
            // Firebase limiti: Her 500 işlemde bir gönderip sıfırla
            if (counter == 450) {
              await batch.commit();
              batch = firestore.batch();
              counter = 0;
              print("$lesson için ara kayıt yapıldı...");
            }
          }
        }
        
        // Kalan son partiyi gönder
        await batch.commit();
        print("$lesson dersi başarıyla yüklendi/güncellendi! ✅");

      } catch (e) {
        print("HATA ($lesson): $e ❌");
      }
    }
    print("TÜM İŞLEMLER BİTTİ! 🎉");
  }
}
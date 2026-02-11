import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Yedek olarak kalsın

class QuizService {

  // 🔥 Tek Bir Sınavın Sonucunu Getir (Review için)
  static Future<Map<String, dynamic>?> getQuizResult(String topic, int testNo) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      // O konuya ve test numarasına ait en son çözülen sınavı getir
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('results')
          .where('topic', isEqualTo: topic)
          .where('testNo', isEqualTo: testNo)
          .orderBy('timestamp', descending: true) // En son çözüleni al
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print("Hata (getQuizResult): $e");
      return null;
    }
  }
  
  // 🔥 Çözülen Testlerin Numaralarını Getir (Firebase'den)
  static Future<List<int>> getCompletedTests(String topic) async {
    User? user = FirebaseAuth.instance.currentUser;
    
    // Eğer kullanıcı giriş yapmamışsa boş döndür (veya yerel bakılabilir)
    if (user == null) return [];

    try {
      // 'results' koleksiyonunda, şu anki konuyla ilgili tüm sonuçları çek
      // Sadece 'testNo' alanını çekmek yeterli, gereksiz veri indirmeyelim.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('results')
          .where('topic', isEqualTo: topic)
          .get();

      // Dökümanlardan test numaralarını alıp listeye çevir
      // Set kullanarak aynı testin 2 kere listeye girmesini engelleriz
      Set<int> completedTests = {};
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('testNo')) {
          completedTests.add(data['testNo'] as int);
        }
      }

      return completedTests.toList();
      
    } catch (e) {
      print("Hata (getCompletedTests): $e");
      return [];
    }
  }

  // 🔥 Sonuç Kaydetme (Hem Local Hem Firebase Destekli)
static Future<void> saveQuizResult({
  required String topic,
  required int testNo,
  required int score,
  required int correctCount,
  required int wrongCount,
  required int emptyCount, // Bunu da eklemen iyi olur
  List<int?>? userAnswers,
}) async {
  User? user = FirebaseAuth.instance.currentUser;

  // 1. Yerel Kayıt (Hız ve çevrimdışı kullanım için)
  final prefs = await SharedPreferences.getInstance();
  List<String> results = prefs.getStringList('quiz_results') ?? [];
  String resultJson = "$topic|$testNo|$score|$correctCount|$wrongCount|${DateTime.now()}";
  results.add(resultJson);
  await prefs.setStringList('quiz_results', results);

  // 2. 🔥 Firebase Kaydı (Burayı mutlaka açmalısın)
  if (user != null) {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('results')
          .add({
        'topic': topic,
        'testNo': testNo,
        'score': score,
        'correct': correctCount,
        'wrong': wrongCount,
        'empty': emptyCount,
        'timestamp': FieldValue.serverTimestamp(),
        // İstersen cevap anahtarını da tutabilirsin (analiz için)
        // 'userAnswers': userAnswers 
      });
    } catch (e) {
      print("Firebase kayıt hatası: $e");
      // Hata olursa yerel kayıttan sonra senkronize edecek bir yapı kurabilirsin.
    }
  }
}
  
  // Test İstatistiklerini Getir (Opsiyonel - Test Listesinde Puan Göstermek İstersen)
  static Future<Map<int, int>> getTestScores(String topic) async {
     User? user = FirebaseAuth.instance.currentUser;
     if (user == null) return {};
     
     try {
       QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('results')
          .where('topic', isEqualTo: topic)
          .get();
          
       Map<int, int> scores = {};
       for (var doc in snapshot.docs) {
         var data = doc.data() as Map<String, dynamic>;
         int tNo = data['testNo'];
         int sc = data['score'];
         // Eğer aynı testi birden fazla çözdüyse en yüksek puanı al
         if (!scores.containsKey(tNo) || sc > scores[tNo]!) {
           scores[tNo] = sc;
         }
       }
       return scores;
     } catch (e) {
       return {};
     }
  }
}
// lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import '../models/question_model.dart';
import 'quiz_screen.dart';
import '../services/achievement_service.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultScreen extends StatefulWidget {
  final List<Question> questions;
  final List<int?> userAnswers;
  final String topic;
  final int testNo;
  final int correctCount;
  final int wrongCount;
  final int emptyCount;
  final int score;

  const ResultScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.topic,
    required this.testNo,
    required this.correctCount,
    required this.wrongCount,
    required this.emptyCount,
    required this.score,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  
  @override
  void initState() {
    super.initState();
    
    // Rozet kontrolleri
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AchievementService.instance.incrementCategory(
        context, 
        widget.topic,
        widget.correctCount, 
      );

      AchievementService.instance.checkTimeAndScore(
        context, 
        widget.score, 
        100, 
        widget.correctCount 
      );
      _updateStreakAndStats();
    });
  }

  // 🔥 YENİ FONKSİYON: Hem Streak'i hem Toplam Çözüleni günceller
  Future<void> _updateStreakAndStats() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    
    try {
      // 1. Mevcut veriyi çek
      DocumentSnapshot doc = await userDocRef.get();
      if (!doc.exists) return;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      String today = DateTime.now().toIso8601String().split('T')[0];
      String lastStudyDate = data['lastStudyDate'] ?? ""; // lastActivity değil, StudyDate!
      int currentStreak = data['streak'] ?? 0;
      int newStreak = currentStreak;

      // 2. Streak Hesaplama (Eğer bugün daha önce çözmediyse)
      if (lastStudyDate != today) {
        if (lastStudyDate.isNotEmpty) {
           DateTime dateToday = DateTime.parse(today);
           DateTime dateLast = DateTime.parse(lastStudyDate);
           int diff = dateToday.difference(dateLast).inDays;

           if (diff == 1) {
             newStreak++; // Dün çözmüş, seriye devam
           } else {
             newStreak = 1; // Zincir kırılmış veya ilk kez, baştan başla
           }
        } else {
          newStreak = 1; // Hiç tarihi yoksa 1 yap
        }
      }
      
      // 3. Verileri Güncelle (Atomik işlem)
      await userDocRef.update({
        'lastStudyDate': today,           // Bugün ders çalışıldı olarak işaretle
        'streak': newStreak,              // Yeni seri
        'totalSolved': FieldValue.increment(widget.questions.length), // Toplam soru artır
        'totalCorrect': FieldValue.increment(widget.correctCount),    // Toplam doğru artır
        'dailySolved': FieldValue.increment(widget.questions.length), // Günlük soru artır
      });
      
      debugPrint("🔥 Firebase güncellendi: Streak $newStreak oldu.");

    } catch (e) {
      debugPrint("Hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text("Sınav Sonucu 📝"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false, 
      ),
      body: Column(
        children: [
          // --- ÖZET KARTI ---
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Text(
                  "${widget.score} Puan", 
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: widget.score >= 70 ? Colors.green : Colors.orange
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Doğru", widget.correctCount, Colors.green),
                    _buildStatItem("Yanlış", widget.wrongCount, Colors.red),
                    _buildStatItem("Boş", widget.emptyCount, Colors.grey),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Cevap Anahtarı (İncelemek için tıkla)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ),
          ),

          // --- SORU NUMARALARI GRID ---
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: widget.questions.length, 
              itemBuilder: (context, index) {
                int? userAnswer = widget.userAnswers[index]; 
                int correctAnswer = widget.questions[index].answerIndex;
                
                Color bgColor;
                if (userAnswer == null) {
                  bgColor = Colors.grey.shade300; 
                } else if (userAnswer == correctAnswer) {
                  bgColor = Colors.green; 
                } else {
                  bgColor = Colors.red; 
                }

                return InkWell(
                  onTap: () {
                    // İnceleme moduna git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(
                          isTrial: false,
                          topic: widget.topic,
                          testNo: widget.testNo,
                          questions: widget.questions,
                          userAnswers: widget.userAnswers,
                          initialIndex: index,
                          isReviewMode: true,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- ANA SAYFAYA DÖN BUTONU ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // DÜZELTİLEN KISIM BURASI:
                  // Sadece 1 kere pop yapıyoruz.
                  // Çünkü QuizScreen zaten bizi bekliyor, geri dönünce o da kendini kapatacak.
                  Navigator.pop(context); 
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text("Listeye Dön"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text("$count", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
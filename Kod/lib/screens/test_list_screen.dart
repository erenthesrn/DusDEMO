// lib/screens/test_list_screen.dart
import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class TestListScreen extends StatelessWidget {
  final String topic; // Örn: "Anatomi"
  final Color themeColor; // Örn: Colors.orange

  const TestListScreen({
    super.key, 
    required this.topic, 
    required this.themeColor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text("$topic Testleri"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- KOLAY SEVİYE ---
          _buildSectionHeader("Kolay Seviye", Colors.green),
          _buildTestGrid(context, count: 8, difficulty: "Kolay", color: Colors.green),
          
          _buildDivider(),

          // --- ORTA SEVİYE ---
          _buildSectionHeader("Orta Seviye", Colors.orange),
          _buildTestGrid(context, count: 8, difficulty: "Orta", color: Colors.orange),

          _buildDivider(),

          // --- ZOR SEVİYE ---
          _buildSectionHeader("Zor Seviye", Colors.red),
          _buildTestGrid(context, count: 8, difficulty: "Zor", color: Colors.red),
          
          const SizedBox(height: 40), // Alt boşluk
        ],
      ),
    );
  }

  // --- İNCE ŞERİT (DIVIDER) ---
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Divider(color: Colors.grey.withOpacity(0.3), thickness: 1),
    );
  }

  // --- BAŞLIK TASARIMI ---
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // --- TEST KUTULARI (GRID) ---
  Widget _buildTestGrid(BuildContext context, {required int count, required String difficulty, required Color color}) {
    return GridView.builder(
      shrinkWrap: true, // ListView içinde çalışması için şart
      physics: const NeverScrollableScrollPhysics(), // Kaydırmayı engelle (ListView kaydırıyor zaten)
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Yan yana 4 kutu
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        int testNumber = index + 1;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Teste Tıklanınca Quiz Ekranına Git
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => QuizScreen(
                  isTrial: false, 
                  // İleride bu bilgileri veritabanından soru çekmek için kullanacağız:
                  // topic: topic, 
                  // difficulty: difficulty,
                  // testNumber: testNumber
                ))
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: color.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$testNumber", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)
                  ),
                  Text(
                    "Test", 
                    style: TextStyle(fontSize: 10, color: Colors.grey[600])
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
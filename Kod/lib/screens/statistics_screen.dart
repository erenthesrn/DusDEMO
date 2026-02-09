import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Grafikler için gerekli
import 'package:percent_indicator/percent_indicator.dart'; // Dairesel gösterge için
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '/services/theme_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Veri Değişkenleri
  bool _isLoading = true;
  int _totalSolved = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;
  Map<String, double> _subjectPerformance = {};
  
  // Örnek grafik verisi (Gerçek veriyi Firebase'den çekip buraya mapleyebilirsin)
  final List<FlSpot> _weeklyProgress = const [
    FlSpot(1, 15),
    FlSpot(2, 25),
    FlSpot(3, 20),
    FlSpot(4, 40),
    FlSpot(5, 35),
    FlSpot(6, 60),
    FlSpot(7, 65), // Bugün
  ];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Firebase'den Genel Verileri Çek
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        
        setState(() {
          _totalSolved = data['totalSolved'] ?? 0;
          _totalCorrect = data['totalCorrect'] ?? 0;
          _totalWrong = _totalSolved - _totalCorrect; // Basit hesaplama
          
          // Ders bazlı performans (İleride bunu detaylandırabilirsin)
          _subjectPerformance = {
            "Anatomi": 0.75,
            "Biyokimya": 0.40,
            "Fizyoloji": 0.60,
            "Farmakoloji": 0.85,
            "Patoloji": 0.30,
            "Klinik Bilimler": 0.55,
          };
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("İstatistik hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.instance;
    final isDarkMode = themeProvider.isDarkMode;

    // Arka Plan (Profile Screen ile aynı uyumda)
    Widget background = isDarkMode 
      ? Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0E14), Color(0xFF161B22)]
            )
          ),
        )
      : Container(color: const Color.fromARGB(255, 236, 242, 255));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("İstatistiklerim", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          background,
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
              child: Column(
                children: [
                  // 1. GENEL BAŞARI KARTI
                  _buildGlassContainer(
                    isDark: isDarkMode,
                    child: _buildSuccessSummary(isDarkMode),
                  ),
                  
                  const SizedBox(height: 20),

                  // 2. DETAYLI SAYILAR (GRID)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard("Toplam Soru", "$_totalSolved", Icons.assignment, Colors.blue, isDarkMode),
                      _buildStatCard("Doğru", "$_totalCorrect", Icons.check_circle, Colors.green, isDarkMode),
                      _buildStatCard("Yanlış", "$_totalWrong", Icons.cancel, Colors.red, isDarkMode),
                      _buildStatCard("Net Ort.", "${(_totalCorrect - (_totalWrong / 4)).toStringAsFixed(1)}", Icons.timeline, Colors.orange, isDarkMode),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. HAFTALIK GRAFİK
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Haftalık İlerleme 📈", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                  ),
                  const SizedBox(height: 10),
                  _buildGlassContainer(
                    isDark: isDarkMode,
                    padding: const EdgeInsets.fromLTRB(10, 25, 20, 10),
                    child: AspectRatio(
                      aspectRatio: 1.7,
                      child: _buildLineChart(isDarkMode),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. DERS BAZLI PERFORMANS
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Ders Analizi 📚", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                  ),
                  const SizedBox(height: 10),
                  _buildGlassContainer(
                    isDark: isDarkMode,
                    child: Column(
                      children: _subjectPerformance.entries.map((entry) {
                        return _buildSubjectBar(entry.key, entry.value, isDarkMode);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET PARÇALARI ---

  // 1. Büyük Başarı Özeti (Circular Percent Indicator)
  Widget _buildSuccessSummary(bool isDark) {
    double successRate = _totalSolved == 0 ? 0 : (_totalCorrect / _totalSolved);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        CircularPercentIndicator(
          radius: 60.0,
          lineWidth: 10.0,
          animation: true,
          percent: successRate,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "%${(successRate * 100).toInt()}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: isDark ? Colors.white : Colors.black),
              ),
              Text("Başarı", style: TextStyle(fontSize: 12.0, color: isDark ? Colors.white60 : Colors.grey)),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: const Color(0xFF00C6FF), // Neon Mavi
          backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Durum Analizi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildLegendItem(Icons.circle, Colors.green, "Güçlü: Anatomi"),
            const SizedBox(height: 4),
            _buildLegendItem(Icons.circle, Colors.red, "Zayıf: Patoloji"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Text("Hedef: Cerrahi 🎯", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  // 2. Küçük İstatistik Kartları
  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2732) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
        ],
      ),
    );
  }

  // 3. Çizgi Grafik (Line Chart)
  Widget _buildLineChart(bool isDark) {
    List<Color> gradientColors = [
      const Color(0xFF23b6e6),
      const Color(0xFF02d39a),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.grey.shade300, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 1: return const Text('Pzt', style: TextStyle(fontSize: 10));
                  case 4: return const Text('Prş', style: TextStyle(fontSize: 10));
                  case 7: return const Text('Paz', style: TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 8,
        minY: 0,
        maxY: 80,
        lineBarsData: [
          LineChartBarData(
            spots: _weeklyProgress,
            isCurved: true,
            gradient: LinearGradient(colors: gradientColors),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: gradientColors.map((color) => color.withOpacity(0.3)).toList()),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Ders İlerleme Çubuğu
  Widget _buildSubjectBar(String subject, double percent, bool isDark) {
    Color getColor(double p) {
      if (p >= 0.75) return Colors.green;
      if (p >= 0.50) return Colors.orange;
      return Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text("%${(percent * 100).toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: getColor(percent))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(getColor(percent)),
            ),
          ),
        ],
      ),
    );
  }

  // --- GLASS CONTAINER YARDIMCISI ---
  Widget _buildGlassContainer({required Widget child, required bool isDark, EdgeInsetsGeometry padding = const EdgeInsets.all(20)}) {
    if (!isDark) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2732).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}
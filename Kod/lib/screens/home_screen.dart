import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
// lib/screens/home_screen.dart en üste ekle:
import '../services/mistakes_service.dart';
import '../models/question_model.dart';

// --- MEVCUT SAYFA IMPORTLARI ---
import 'topic_selection_screen.dart'; 
import 'profile_screen.dart';
import 'quiz_screen.dart'; 
import 'mistakes_screen.dart';
import 'blog_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // --- VERİ DEĞİŞKENLERİ ---
  String _targetBranch = "Hedef Seçiliyor...";
  int _dailyGoal = 60;
  int _currentMinutes = 0;
  int _totalSolved = 0;
  int _totalCorrect = 0; 
  bool _isLoading = true; // ignore: unused_field

  late ConfettiController _confettiController;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _listenToUserData(); // Canlı dinlemeyi başlat
  }

  @override
  void dispose() {
    _userSubscription?.cancel(); // Sayfadan çıkınca dinlemeyi durdur
    _confettiController.dispose();
    super.dispose();
  }

  // --- FIREBASE VERİ CANLI TAKİP (STREAM) ---
  void _listenToUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        
        if (snapshot.exists && snapshot.data() != null) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          
          if (mounted) {
            setState(() {
              if (data.containsKey('targetBranch')) _targetBranch = data['targetBranch'];
              if (data.containsKey('dailyGoalMinutes')) _dailyGoal = (data['dailyGoalMinutes'] as num).toInt();
              if (data.containsKey('totalMinutes')) _currentMinutes = (data['totalMinutes'] as num).toInt();
              if (data.containsKey('totalSolved')) _totalSolved = (data['totalSolved'] as num).toInt();
              if (data.containsKey('totalCorrect')) {
                _totalCorrect = (data['totalCorrect'] as num).toInt();
              } else {
                _totalCorrect = 0; 
              }
              _isLoading = false;
            });
          }
        }
      }, onError: (e) {
        debugPrint("Veri dinleme hatası: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> currentPages = [
      DashboardScreen(
        targetBranch: _targetBranch,
        dailyGoal: _dailyGoal,
        currentMinutes: _currentMinutes,
        totalSolved: _totalSolved,
        totalCorrect: _totalCorrect,
        onRefresh: () {}, // Stream olduğu için manuel refreshe gerek kalmadı
      ),
      const BlogScreen(),
      const Scaffold(body: Center(child: Text("Analiz Ekranı Hazırlanıyor..."))),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: currentPages,
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: NavigationBar(
            height: 80,
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: Colors.transparent,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            destinations: [
              _buildNavDest(Icons.home_outlined, Icons.home, 0),
              _buildNavDest(Icons.book_outlined, Icons.book, 1),
              _buildNavDest(Icons.bar_chart_outlined, Icons.bar_chart, 2),
              _buildNavDest(Icons.person_outline, Icons.person, 3),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDest(IconData icon, IconData activeIcon, int idx) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.blueGrey.shade400, size: 28),
      selectedIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(activeIcon, color: const Color(0xFF0D9488), size: 28),
          const SizedBox(height: 4),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF0D9488), shape: BoxShape.circle)),
        ],
      ),
      label: '',
    );
  }
}

// =============================================================================
// ||                          DASHBOARD EKRANI                               ||
// =============================================================================

class DashboardScreen extends StatelessWidget {
  final String targetBranch;
  final int dailyGoal;
  final int currentMinutes;
  final int totalSolved;
  final int totalCorrect;
  final VoidCallback onRefresh;

  const DashboardScreen({
    super.key,
    required this.targetBranch,
    required this.dailyGoal,
    required this.currentMinutes,
    required this.totalSolved,
    required this.totalCorrect,
    required this.onRefresh,
  });

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Günaydın';
    if (hour >= 12 && hour < 17) return 'İyi Günler';
    if (hour >= 17 && hour < 23) return 'İyi Akşamlar';
    return 'İyi Geceler';
  }

  String _calculateSuccessRate() {
    if (totalSolved == 0) return '%0';
    double rate = (totalCorrect.toDouble() / totalSolved.toDouble()) * 100;
    return '%${rate.toStringAsFixed(0)}';
  }

// --- GÜNCELLENMİŞ ÇALIŞMA ALANI SEÇİMİ ---
// --- GÜNCELLENMİŞ MODERN ÇALIŞMA ALANI SEÇİMİ ---
void _showTopicSelection(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // Arka planı şeffaf yapıyoruz ki köşeleri biz yönetelim
    isScrollControlled: true,
    builder: (context) => Container(
      height: 480, 
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gri Çizgi (Sürükleme İşareti)
          Center(
            child: Container(
              width: 40, height: 4, 
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))
            ),
          ),
          
          Text("Çalışma Alanı", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text("Hangi alanda pratik yapmak istersin?", style: GoogleFonts.inter(fontSize: 14, color: Colors.blueGrey.shade400)),
          const SizedBox(height: 32),
          
          // --- TEMEL VE KLİNİK (YAN YANA KARTLAR) ---
          Row(
            children: [
              Expanded(
                child: _buildModernCard(
                  context, 
                  title: "Temel\nBilimler", 
                  icon: Icons.biotech_outlined, 
                  color: Colors.orange, 
                  topics: ["Anatomi","Histoloji ve Embriyoloji" ,"Fizyoloji", "Biyokimya", "Mikrobiyoloji", "Patoloji", "Farmakoloji","Biyoloji ve Genetik"]
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernCard(
                  context, 
                  title: "Klinik\nBilimler", 
                  icon: Icons.health_and_safety_outlined, 
                  color: Colors.blue, 
                  topics: ["Protetik Diş Tedavisi", "Restoratif Diş Tedavisi", "Endodonti", "Periodontoloji", "Ortodonti", "Pedodonti", "Ağız, Diş ve Çene Cerrahisi", "Ağız, Diş ve Çene Radyolojisi"]
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // --- SINAV PROVASI (GENİŞ KART) ---
          _buildModernCard(
            context,
            title: "Sınav Provası",
            subtitle: "Tüm derslerden karışık deneme",
            icon: Icons.timer_outlined,
            color: const Color(0xFF673AB7),
            isWide: true,
            onTapOverride: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen(isTrial: true, fixedDuration: 150)));
            }
          ),
        ],
      ),
    ),
  );
}
// --- MODERN KART TASARIMI (INKWELL İLE TIKLAMA HİSSİYATI) ---
Widget _buildModernCard(BuildContext context, {
  required String title, 
  required IconData icon, 
  required Color color, 
  List<String>? topics,
  String? subtitle,
  bool isWide = false,
  VoidCallback? onTapOverride
}) {
  return Container(
    height: isWide ? 100 : 160,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.grey.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
      ]
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        onTap: onTapOverride ?? () {
          Navigator.pop(context);
          if (topics != null) {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => TopicSelectionScreen(title: title.replaceAll('\n', ' '), topics: topics, themeColor: color))
            ).then((_) => onRefresh());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isWide 
          ? Row( // Geniş kart (Sınav Provası için)
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    if (subtitle != null)
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey)),
                  ],
                )
              ],
            )
          : Column( // Dikey kartlar (Dersler için)
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 32),
                ),
                Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), height: 1.2)),
              ],
            ),
        ),
      ),
    ),
  );
}

  void _showDenemeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Deneme Modu", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.timer, color: Colors.red)),
              title: const Text("Genel Deneme (150 dk)"),
              subtitle: const Text("Gerçek sınav provası"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen(isTrial: true, fixedDuration: 150)));
              },
            ),
             ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.science, color: Colors.blue)),
              title: const Text("Klinik Deneme"),
              subtitle: const Text("Sadece klinik dersler"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen(isTrial: true)));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // --- HEADER KISMI ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1), 
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_getGreeting()}, Doktor', 
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        
                        SizedBox(
                          width: 300, 
                          child: Text(
                            'Hedef: $targetBranch Uzmanlığı', 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold) 
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.notifications_none, color: Colors.white),
                    )
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _buildMiniStat(Icons.check_circle_outline, '$totalSolved', 'Çözülen Soru', Colors.orange.shade400),
                    const SizedBox(width: 16),
                    _buildMiniStat(Icons.track_changes, _calculateSuccessRate(), 'Başarı Oranı', Colors.green.shade400),
                  ],
                ),
              ],
            ),
          ),

          // --- HEDEF KARTLARI (PROGRESS CIRCLE DÜZELTİLDİ) ---
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Bugünkü Hedefler", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                        TextButton(
                          onPressed: onRefresh, 
                          child: const Text("Yenile", style: TextStyle(color: Colors.orange)),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // SORU HEDEFİ (100 soru varsayılan)
                        Expanded(
                          child: _buildGoalCircle(
                            '$totalSolved', 
                            '100 Soru', 
                            Colors.teal,
                            (totalSolved / 100).clamp(0.0, 1.0) // İlerleme Oranı
                          )
                        ),
                        Container(width: 1, height: 60, color: Colors.blueGrey.shade100),
                        // SÜRE HEDEFİ
                        Expanded(
                          child: _buildGoalCircle(
                            '$currentMinutes', 
                            '$dailyGoal Dakika', 
                            Colors.orange,
                            dailyGoal > 0 ? (currentMinutes / dailyGoal).clamp(0.0, 1.0) : 0.0 // İlerleme Oranı
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- GRID BUTONLAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double itemWidth = (constraints.maxWidth - 32) / 3;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionBtn('Pratik', 'Soru Çöz', Icons.play_arrow, const Color(0xFF0D47A1), itemWidth,
                      onTap: () => _showTopicSelection(context)),
                    
                    _buildActionBtn('Bilgi Kartları', 'Hızlı Tekrar', Icons.emoji_events, const Color.fromARGB(255, 0, 150, 136), itemWidth,
                      onTap: () {
                        // Şimdilik boş, daha sonra doldurulacak
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bilgi Kartları modülü hazırlanıyor..."))
                      );
                      }),                    
                    _buildActionBtn('Yanlışlar', 'Hatalarını Gör', Icons.refresh, const Color.fromARGB(255, 205, 16, 35), itemWidth,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MistakesDashboard()));
                      }),
                  ],
                );
              }
            ),
          ),

          const SizedBox(height: 32),
          // --- ALT İSTATİSTİK BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Genel İlerleme', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('$totalSolved / 4764', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: totalSolved / 4764, 
                  backgroundColor: Colors.blueGrey.shade100, 
                  color: const Color(0xFF0D9488), 
                  borderRadius: BorderRadius.circular(10), 
                  minHeight: 10
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildMiniStat(IconData icon, String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(val, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(label, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Düzeltilmiş Daire Fonksiyonu (4 Parametreli)
  Widget _buildGoalCircle(String val, String sub, Color color, double progress) {
    return Column(
      children: [
        SizedBox(
          width: 70, height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Arka plandaki silik halka
              CircularProgressIndicator(
                value: 1.0, 
                color: color.withOpacity(0.1),
                strokeWidth: 6, 
              ),
              // 2. İlerleme halkası (progress değerine göre dolar)
              CircularProgressIndicator(
                value: progress, 
                color: color,
                strokeWidth: 6,
                strokeCap: StrokeCap.round, 
              ),
              // 3. Ortadaki Değer
              Center(
                child: Text(val, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(sub, style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionBtn(String title, String sub, IconData icon, Color color, double width, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 20)),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(sub, maxLines: 2, style: GoogleFonts.inter(color: Colors.white70, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';

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
  // ignore: unused_field
  bool _isLoading = true;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _fetchUserData(); // Verileri çek
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- FIREBASE VERİ ÇEKME ---
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          setState(() {
            if (data.containsKey('targetBranch')) _targetBranch = data['targetBranch'];
            if (data.containsKey('dailyGoalMinutes')) _dailyGoal = (data['dailyGoalMinutes'] as num).toInt();
            if (data.containsKey('totalMinutes')) _currentMinutes = (data['totalMinutes'] as num).toInt();
            if (data.containsKey('totalSolved')) _totalSolved = (data['totalSolved'] as num).toInt();
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Hata: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sayfa listesini güncelle (Verileri Dashboard'a aktar)
    List<Widget> currentPages = [
      DashboardScreen(
        targetBranch: _targetBranch,
        dailyGoal: _dailyGoal,
        currentMinutes: _currentMinutes,
        totalSolved: _totalSolved,
        onRefresh: _fetchUserData, // Geri dönünce veriyi güncelle
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
              _buildNavDest(Icons.book_outlined, Icons.book, 1), // Kütüphane / Blog
              _buildNavDest(Icons.bar_chart_outlined, Icons.bar_chart, 2),
              _buildNavDest(Icons.person_outline, Icons.person, 3),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDest(IconData icon, IconData activeIcon, int idx) {
    // ignore: unused_local_variable
    final isActive = _selectedIndex == idx;
    return NavigationDestination(
      // DÜZELTME 1: Colors.slate -> Colors.blueGrey
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
// ||                       YENİ TASARIMLI DASHBOARD                          ||
// =============================================================================

class DashboardScreen extends StatelessWidget {
  final String targetBranch;
  final int dailyGoal;
  final int currentMinutes;
  final int totalSolved;
  final VoidCallback onRefresh;

  const DashboardScreen({
    super.key,
    required this.targetBranch,
    required this.dailyGoal,
    required this.currentMinutes,
    required this.totalSolved,
    required this.onRefresh,
  });

  // --- 1. Konu Seçimi Bottom Sheet ---
  void _showTopicSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text("Çalışma Alanı Seç", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSheetOption(
                    context, "Temel Bilimler", Colors.orange, 
                    ["Anatomi","Histoloji ve Embriyoloji" ,"Fizyoloji", "Biyokimya", "Mikrobiyoloji", "Patoloji", "Farmakoloji","Biyoloji ve Genetik"]
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSheetOption(
                    context, "Klinik Bilimler", Colors.blue, 
                    ["Protetik Diş Tedavisi", "Restoratif Diş Tedavisi", "Endodonti", "Periodontoloji", "Ortodonti", "Pedodonti", "Ağız, Diş ve Çene Cerrahisi", "Ağız, Diş ve Çene Radyolojisi"]
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption(BuildContext context, String title, Color color, List<String> topics) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => TopicSelectionScreen(title: title, topics: topics, themeColor: color))
        ).then((_) => onRefresh());
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- 2. Deneme Sınavı Bottom Sheet ---
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
          // HEADER (TEAL ALAN)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 13, 72, 161),
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
                        Text('İyi Akşamlar,', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        SizedBox(
                          width: 200,
                          child: Text(targetBranch, 
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                    _buildMiniStat(Icons.track_changes, '%74', 'Başarı Oranı', Colors.green.shade400),
                  ],
                ),
              ],
            ),
          ),

          // GOAL CARD (BEYAZ KART)
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
                          onPressed: onRefresh, // Yenile butonu
                          child: const Text("Yenile", style: TextStyle(color: Colors.orange)),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // Hedef Soru (Sabit 100 varsayalım veya DB'den çekilebilir)
                        Expanded(child: _buildGoalCircle('0', '100 Soru', Colors.teal)),
                        // DÜZELTME 2: Colors.slate -> Colors.blueGrey
                        Container(width: 1, height: 60, color: Colors.blueGrey.shade100),
                        // Hedef Süre (Firebase'den gelen)
                        Expanded(child: _buildGoalCircle('$currentMinutes', '$dailyGoal Dakika', Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ACTION GRID (BUTONLAR)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double itemWidth = (constraints.maxWidth - 32) / 3;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. PRATİK (Soru Çözme)
                    _buildActionBtn('Pratik', 'Soru Çöz', Icons.play_arrow, const Color(0xFF0D47A1), itemWidth,
                      onTap: () => _showTopicSelection(context)),
                    
                    // 2. DENEME (Sınav)
                    _buildActionBtn('Deneme', 'Süre tut', Icons.emoji_events, const Color.fromARGB(255, 0, 150, 136), itemWidth,
                      onTap: () => _showDenemeSelection(context)),
                    
                    // 3. YANLIŞLARIM (Eski MistakesScreen)
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
          // ALT İSTATİSTİK BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Genel İlerleme', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    // DÜZELTME 3: Colors.slate -> Colors.blueGrey
                    Text('$totalSolved / 4764', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: totalSolved / 4764, // Örnek oran
                  // DÜZELTME 4: Colors.slate -> Colors.blueGrey
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

  // --- WIDGET BUILDERS ---
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

  Widget _buildGoalCircle(String val, String sub, Color color) {
    return Column(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.1), width: 4)),
          alignment: Alignment.center,
          // DÜZELTME 5: FontWeight.black -> FontWeight.w900
          child: Text(val, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ),
        const SizedBox(height: 12),
        // DÜZELTME 6: Colors.slate -> Colors.blueGrey
        // DÜZELTME 7: FontWeight.medium -> FontWeight.w500
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
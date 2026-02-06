import 'package:flutter/material.dart';
import '../services/mistakes_service.dart';
import '../models/question_model.dart';
import 'quiz_screen.dart'; 

// ==========================================
// 1. EKRAN: YANLIŞLARIM KOKPİTİ (Dashboard)
// ==========================================

enum SortOption { newest, oldest, subject, random }

class MistakesDashboard extends StatefulWidget {
  const MistakesDashboard({super.key});

  @override
  State<MistakesDashboard> createState() => _MistakesDashboardState();
}

class _MistakesDashboardState extends State<MistakesDashboard> {
  List<Map<String, dynamic>> _allMistakes = [];
  bool _isLoading = true;

  // Ders İsimleri ve Renkleri
  final Map<String, Color> _subjectColors = {
    "Anatomi": Colors.orange,
    "Histoloji ve Embriyoloji": Colors.pinkAccent,
    "Fizyoloji": Colors.redAccent,
    "Biyokimya": Colors.purple,
    "Mikrobiyoloji": Colors.green,
    "Patoloji": Colors.brown,
    "Farmakoloji": Colors.teal,
    "Biyoloji ve Genetik": Colors.lime,

    // KLİNİK BİLİMLER
    "Protetik Diş Tedavisi": Colors.cyan,
    "Restoratif Diş Tedavisi": Colors.lightBlue,
    "Endodonti": Colors.yellow.shade800,
    "Periodontoloji": Colors.deepOrange,
    "Ortodonti": Colors.indigo,
    "Pedodonti": Colors.amber,
    "Ağız, Diş ve Çene Cerrahisi": Colors.red.shade900,
    "Ağız, Diş ve Çene Radyolojisi": Colors.blueGrey,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var data = await MistakesService.getMistakes();
    if (mounted) {
      setState(() {
        _allMistakes = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hangi dersten kaç yanlış var hesapla
    Map<String, int> counts = {};
    for (var m in _allMistakes) {
      String sub = m['subject'] ?? "Diğer";
      counts[sub] = (counts[sub] ?? 0) + 1;
    }

    List<String> sortedSubjects = _subjectColors.keys.toList();

    sortedSubjects.sort((a, b) {
      int countA = counts[a] ?? 0;
      int countB = counts[b] ?? 0;

      // Kural 1: Yanlış sayısı ÇOK olan en üste (Descending)
      if (countB != countA) {
        return countB.compareTo(countA);
      }
      // Kural 2: Yanlış sayıları EŞİT ise alfabetik sırala (Ascending)
      else {
        return a.compareTo(b);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1), // Hafif Teal tonu
      appBar: AppBar(
        title: const Text("Eksiklerimi Kapat",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allMistakes.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ÜST KART: TOPLAM YANLIŞ
                      _buildSummaryCard(_allMistakes.length),

                      const SizedBox(height: 24),
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Derslere Göre Hatalar (Çoktan Aza)",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 12),

                      // GRID MENU
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: sortedSubjects.length,
                        itemBuilder: (context, index) {
                          String subject = sortedSubjects[index];
                          int count = counts[subject] ?? 0; // O dersin yanlış sayısı
                          return _buildSubjectCard(
                              subject, count, _subjectColors[subject]!);
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 80, color: Colors.teal.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("Harikasın! Hiç yanlışın yok.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Test çözdükçe burası dolacak.",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.teal.shade700]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          const Text("Toplam Hatalı Soru",
              style: TextStyle(color: Colors.white70)),
          Text("$total",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Tüm yanlışları aç
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MistakesListScreen(
                          mistakes: _allMistakes, title: "Tüm Yanlışlarım")));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: Colors.teal),
            child: const Text("Hepsini Tekrar Et"),
          )
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String subject, int count, Color color) {
    return GestureDetector(
      onTap: () {
        if (count > 0) {
          // Sadece o dersin yanlışlarını filtrele ve gönder
          var filtered =
              _allMistakes.where((m) => m['subject'] == subject).toList();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      MistakesListScreen(mistakes: filtered, title: subject)));
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("$subject dersinden henüz yanlışın yok!"),
            duration: const Duration(milliseconds: 1200),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: count > 0 ? color.withOpacity(0.5) : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, color: count > 0 ? color : Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(subject,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: count > 0 ? Colors.black87 : Colors.grey)),
            Text("$count Soru",
                style: TextStyle(
                    color: count > 0 ? color : Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. EKRAN: YANLIŞ SORULARIN LİSTESİ
// ==========================================
class MistakesListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> mistakes;
  final String title;

  const MistakesListScreen(
      {super.key, required this.mistakes, required this.title});

  @override
  State<MistakesListScreen> createState() => _MistakesListScreenState();
}

class _MistakesListScreenState extends State<MistakesListScreen> {
  late List<Map<String, dynamic>> _currentList;
  SortOption _currentSort = SortOption.newest; 

  @override
  void initState() {
    super.initState();
    _currentList = List.from(widget.mistakes);
    _sortList(); 
  }

  void _sortList() {
    setState(() {
      switch (_currentSort) {
        case SortOption.newest:
          _currentList.sort((a, b) {
            DateTime dateA =
                DateTime.tryParse(a['date'] ?? "") ?? DateTime(2020);
            DateTime dateB =
                DateTime.tryParse(b['date'] ?? "") ?? DateTime(2020);
            return dateB.compareTo(dateA); 
          });
          break;
        case SortOption.oldest:
          _currentList.sort((a, b) {
            DateTime dateA =
                DateTime.tryParse(a['date'] ?? "") ?? DateTime(2020);
            DateTime dateB =
                DateTime.tryParse(b['date'] ?? "") ?? DateTime(2020);
            return dateA.compareTo(dateB); 
          });
          break;
        case SortOption.subject:
          _currentList.sort((a, b) =>
              (a['subject'] ?? "").compareTo(b['subject'] ?? ""));
          break;
        case SortOption.random:
          _currentList.shuffle(); 
          break;
      }
    });
  }

  // --- YENİ EKLENEN KISIM: QUIZ BAŞLATMA ---
// --- YENİ EKLENEN KISIM: QUIZ BAŞLATMA ---
  void _startMistakeQuiz() async {
    // Verileri Question Modeline çeviriyoruz
    List<Question> questionList = _currentList.map<Question>((m) {
      return Question(
        id: m['id'],
        question: m['question'],
        options: List<String>.from(m['options']),
        answerIndex: m['correctIndex'],
        explanation: m['explanation'] ?? "",
        testNo: 0,
        // 🔥 DÜZELTME BURADA: "Karışık" yerine m['subject'] kullanıyoruz.
        level: m['subject'] ?? "Genel", 
      );
    }).toList();

    // ... kodun devamı aynı ...

    // Quiz ekranına git ve dönmesini bekle
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          isTrial: false,
          topic: widget.title,
          questions: questionList,
          userAnswers: null,
        ),
      ),
    );
    
    // Quiz bitip geri dönüldüğünde listeyi yenile
    _refreshList(); 
  }

  // --- LİSTEYİ YENİLEME ---
  Future<void> _refreshList() async {
    var allData = await MistakesService.getMistakes();
    if (mounted) {
      setState(() {
        if (widget.title == "Tüm Yanlışlarım") {
          _currentList = allData;
        } else {
          _currentList = allData.where((m) => m['subject'] == widget.title).toList();
        }
        _sortList(); 
      });
    }
  }

  Future<void> _deleteMistake(int id, String subject) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Öğrendin mi?"),
          ],
        ),
        content: const Text(
          "Bu soruyu tamamen kavradıysan listeden silelim. Bir daha karşına çıkmayacak. Emin misin?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hayır, Kalsın",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Evet, Sil Gitsin!",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await MistakesService.removeMistake(id, subject);

      if (mounted) {
        setState(() {
          _currentList
              .removeWhere((m) => m['id'] == id && m['subject'] == subject);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text("Süper! Bir eksiği daha kapattın.")),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );

        if (_currentList.isEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
      // --- EKLENEN BUTON ---
      floatingActionButton: _currentList.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: _startMistakeQuiz,
            backgroundColor: Colors.teal,
            icon: const Icon(Icons.play_arrow),
            label: const Text("Bu Yanlışları Çöz"),
          )
        : null,

      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<SortOption>(
            tooltip: "Sırala",
            onSelected: (SortOption result) {
              _currentSort = result;
              _sortList();
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.newest,
                child: Row(
                  children: [
                    Icon(Icons.access_time_filled,
                        color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Text("Yeniden Eskiye"),
                  ],
                ),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.oldest,
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.brown, size: 20),
                    SizedBox(width: 10),
                    Text("Eskiden Yeniye"),
                  ],
                ),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.subject,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text("Derslere Göre (A-Z)"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<SortOption>(
                value: SortOption.random,
                child: Row(
                  children: [
                    Icon(Icons.shuffle, color: Colors.purple, size: 20),
                    SizedBox(width: 10),
                    Text("Karışık Sırala"),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sort_rounded, color: Colors.teal, size: 20),
                  SizedBox(width: 6),
                  Text("Sırala",
                      style: TextStyle(
                          color: Colors.teal, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _currentList.isEmpty
          ? const Center(child: Text("Listede soru kalmadı! 🎉"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _currentList.length,
              itemBuilder: (context, index) {
                final mistake = _currentList[index];
                return _buildMistakeCard(mistake);
              },
            ),
    );
  }

  Widget _buildMistakeCard(Map<String, dynamic> mistake) {
    List<dynamic> options = mistake['options'];
    int correctIndex = mistake['correctIndex'];
    int? wrongIndex = mistake['userIndex'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                    label: Text(mistake['subject'],
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: Colors.blueGrey,
                    padding: EdgeInsets.zero),
                if (wrongIndex == null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: Colors.orange.shade900),
                        const SizedBox(width: 4),
                        Text("BOŞ",
                            style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _deleteMistake(mistake['id'], mistake['subject']),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Anladım"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 113, 185, 117),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(mistake['question'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(options.length, (i) {
              Color color = Colors.transparent;
              IconData? icon;
              if (i == correctIndex) {
                color = Colors.green.withOpacity(0.2);
                icon = Icons.check;
              } else if (wrongIndex != null && i == wrongIndex) {
                color = Colors.red.withOpacity(0.2);
                icon = Icons.close;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Text(String.fromCharCode(65 + i) + ") ",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(options[i])),
                    if (icon != null)
                      Icon(icon, size: 16, color: Colors.black54)
                  ],
                ),
              );
            }),
            if (mistake['explanation'] != null &&
                mistake['explanation'].isNotEmpty) ...[
              const Divider(),
              Text("Açıklama: ${mistake['explanation']}",
                  style: TextStyle(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }
}
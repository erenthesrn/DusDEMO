import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // JSON okumak için şart
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

  // 🔥 JSON VERİLERİNİ FIREBASE ID'LERİ İLE BİRLEŞTİRME
  Future<void> _loadData() async {
    // 1. Eski verileri Firebase'e taşı (Garanti olsun)
    await MistakesService.syncLocalToFirebase();
    
    // 2. Firebase'den Yanlış ID'lerini çek (Sadece TestNo, SoruIndex var)
    var mistakeIDs = await MistakesService.getMistakes();
    
    List<Map<String, dynamic>> fullMistakes = [];
    Map<String, List<dynamic>> jsonCache = {}; // Dosyaları tekrar tekrar okumamak için cache

    // 3. Her bir yanlış için JSON dosyasından metni bul
    for (var m in mistakeIDs) {
      String topic = m['topic']; // veya 'subject' (Servisten ne geliyorsa)
      int testNo = m['testNo'];
      int qIndex = m['questionIndex'];
      String? date = m['date'];
      int id = m['id'] ?? 0; // Silme işlemi için ID lazım

      // Cache kontrolü (Dosya zaten hafızada mı?)
      if (!jsonCache.containsKey(topic)) {
        try {
          String path = 'Assets/data/${topic.toLowerCase()}.json';
          // Biyoloji ve Genetik gibi boşluklu isimler için dosya adı kontrolü gerekebilir
          if(topic == "Ağız, Diş ve Çene Cerrahisi") path = 'Assets/data/cerrahi.json';
          // Diğer özel dosya isimlerini buraya ekleyebilirsin. 
          // Standart şema: anatomi.json, biyokimya.json...
          
          String jsonString = await rootBundle.loadString(path);
          var jsonData = jsonDecode(jsonString);
          
          if (jsonData is Map && jsonData.containsKey(topic)) {
             jsonCache[topic] = jsonData[topic];
          } else if (jsonData is List) {
             jsonCache[topic] = jsonData;
          } else {
             jsonCache[topic] = [];
          }
        } catch (e) {
          print("JSON Hatası ($topic): $e");
          jsonCache[topic] = [];
        }
      }

      // Soruyu Bul
      List<dynamic>? tests = jsonCache[topic];
      if (tests != null && tests.isNotEmpty) {
        var targetTest = tests.firstWhere(
          (t) => t['testNo'] == testNo,
          orElse: () => null,
        );

        if (targetTest != null) {
          List<dynamic> questions = targetTest['questions'];
          if (qIndex < questions.length) {
            var qData = questions[qIndex];
            
            // Tüm veriyi birleştir
            fullMistakes.add({
              'id': id, // Firebase ID'si (Silmek için)
              'topic': topic,
              'subject': topic, // UI 'subject' kullanıyor
              'testNo': testNo,
              'questionIndex': qIndex,
              'question': qData['question'],
              'options': qData['options'],
              'correctIndex': qData['correctOption'],
              'userIndex': -1, // Yanlışlarda kullanıcının ne işaretlediğini tutmuyorsak boş geç
              'explanation': qData['explanation'] ?? "",
              'date': date,
              'fullQuestionData': qData // QuizScreen'e göndermek için ham veri
            });
          }
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _allMistakes = fullMistakes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // İstatistik Hesapla
    Map<String, int> counts = {};
    for (var m in _allMistakes) {
      String sub = m['subject'] ?? "Diğer";
      counts[sub] = (counts[sub] ?? 0) + 1;
    }

    List<String> sortedSubjects = _subjectColors.keys.toList();
    sortedSubjects.sort((a, b) {
      int countA = counts[a] ?? 0;
      int countB = counts[b] ?? 0;
      return countB != countA ? countB.compareTo(countA) : a.compareTo(b);
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFE0F2F1),
      appBar: AppBar(
        title: Text("Eksiklerimi Kapat",
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allMistakes.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryCard(_allMistakes.length),
                        const SizedBox(height: 24),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Derslere Göre Hatalar (Çoktan Aza)",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87))),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: sortedSubjects.length,
                          itemBuilder: (context, index) {
                            String subject = sortedSubjects[index];
                            int count = counts[subject] ?? 0;
                            return _buildSubjectCard(
                                subject, count, _subjectColors[subject] ?? Colors.grey, isDark);
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.teal.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("Harikasın! Hiç yanlışın yok.",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const Text("Test çözdükçe burası dolacak.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          const Text("Toplam Hatalı Soru", style: TextStyle(color: Colors.white70)),
          Text("$total",
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MistakesListScreen(
                          mistakes: _allMistakes, title: "Tüm Yanlışlarım")));
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.teal),
            child: const Text("Hepsini Tekrar Et"),
          )
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String subject, int count, Color color, bool isDark) {
    return GestureDetector(
      onTap: () async {
        if (count > 0) {
          var filtered = _allMistakes.where((m) => m['subject'] == subject).toList();
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MistakesListScreen(mistakes: filtered, title: subject)));
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("$subject dersinden henüz yanlışın yok!"),
            duration: const Duration(seconds: 1),
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: count > 0 ? color.withOpacity(0.5) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
                color: isDark ? Colors.black12 : Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, color: count > 0 ? color : Colors.grey),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(subject,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: count > 0 ? (isDark ? Colors.white : Colors.black87) : Colors.grey)),
            ),
            Text("$count Soru", style: TextStyle(color: count > 0 ? color : Colors.grey, fontSize: 11)),
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

  const MistakesListScreen({super.key, required this.mistakes, required this.title});

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
            // Tarih kontrolü (Eğer null ise en sona at)
            var dateA = a['date'] != null ? DateTime.tryParse(a['date'].toString()) : null;
            var dateB = b['date'] != null ? DateTime.tryParse(b['date'].toString()) : null;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });
          break;
        case SortOption.oldest:
           _currentList.sort((a, b) {
            var dateA = a['date'] != null ? DateTime.tryParse(a['date'].toString()) : null;
            var dateB = b['date'] != null ? DateTime.tryParse(b['date'].toString()) : null;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateA.compareTo(dateB);
          });
          break;
        case SortOption.subject:
          _currentList.sort((a, b) => (a['subject'] ?? "").compareTo(b['subject'] ?? ""));
          break;
        case SortOption.random:
          _currentList.shuffle();
          break;
      }
    });
  }

  void _startMistakeQuiz() async {
    if(_currentList.isEmpty) return;

    List<Question> questionList = _currentList.map<Question>((m) {
      // JSON'dan gelen ham veri (fullQuestionData) varsa onu kullan, yoksa manuel oluştur
      if (m['fullQuestionData'] != null) {
        return Question.fromJson(m['fullQuestionData']);
      }
      return Question(
        id: m['id'] ?? 0,
        question: m['question'] ?? "Soru Yüklenemedi",
        options: List<String>.from(m['options'] ?? []),
        answerIndex: m['correctIndex'] ?? 0,
        explanation: m['explanation'] ?? "",
        testNo: m['testNo'] ?? 0,
        level: m['subject'] ?? "Genel",
      );
    }).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          isTrial: false,
          topic: widget.title,
          questions: questionList,
          userAnswers: null,
          isReviewMode: true, // true yaparsak istatistiklere işlemez, sadece tekrar olur
        ),
      ),
    );
    // Dönüşte listeyi yenilemek istersen _loadData benzeri bir yapı lazım ama
    // dashboard'a dönünce orası yenileyeceği için gerek yok.
  }

  Future<void> _deleteMistake(Map<String, dynamic> mistake) async {
    int id = mistake['id']; // Firebase Doküman ID'si değil, bizim verdiğimiz int ID (timestamp vs.)
    String subject = mistake['topic']; // removeMistake topic ve id istiyor

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misin?"),
        content: const Text("Bu soruyu öğrendiysen listeden silelim."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hayır")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Evet, Öğrendim")
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Firebase'den sil (MistakesService.dart içindeki metodunu kontrol et)
      await MistakesService.removeMistake(id, subject);

      if (mounted) {
        setState(() {
          _currentList.removeWhere((m) => m['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Soru listeden çıkarıldı.")));
        
        if (_currentList.isEmpty) {
          Navigator.pop(context); // Liste boşaldıysa geri dön
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      floatingActionButton: _currentList.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _startMistakeQuiz,
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Bu Yanlışları Çöz"),
            )
          : null,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption result) {
              _currentSort = result;
              _sortList();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem(value: SortOption.newest, child: Text("Yeniden Eskiye")),
              const PopupMenuItem(value: SortOption.oldest, child: Text("Eskiden Yeniye")),
              const PopupMenuItem(value: SortOption.subject, child: Text("Derslere Göre")),
              const PopupMenuItem(value: SortOption.random, child: Text("Karışık")),
            ],
          ),
        ],
      ),
      body: _currentList.isEmpty
          ? Center(child: Text("Listede soru kalmadı! 🎉", style: TextStyle(color: isDark ? Colors.white : Colors.black)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _currentList.length,
              itemBuilder: (context, index) {
                return _buildMistakeCard(_currentList[index], isDark);
              },
            ),
    );
  }

  Widget _buildMistakeCard(Map<String, dynamic> mistake, bool isDark) {
    List<dynamic> options = mistake['options'] ?? [];
    int correctIndex = mistake['correctIndex'] ?? 0;
    // userIndex genelde null gelir çünkü yanlışlar listesinde kullanıcının neyi işaretlediğini tutmuyoruz (yer kazanmak için)
    
    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                    label: Text("${mistake['subject']} - Test ${mistake['testNo']}", 
                        style: const TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: Colors.blueGrey,
                    padding: EdgeInsets.zero),
                IconButton(
                  onPressed: () => _deleteMistake(mistake),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  tooltip: "Öğrendim, sil",
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(mistake['question'] ?? "Soru yüklenemedi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            ...List.generate(options.length, (i) {
              bool isCorrect = (i == correctIndex);
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isCorrect ? Border.all(color: Colors.green.withOpacity(0.5)) : null
                ),
                child: Row(
                  children: [
                    Text("${String.fromCharCode(65 + i)}) ",
                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                    Expanded(child: Text(options[i], style: TextStyle(color: isDark ? Colors.white70 : Colors.black87))),
                    if (isCorrect) const Icon(Icons.check, size: 16, color: Colors.green)
                  ],
                ),
              );
            }),
            if (mistake['explanation'] != null && mistake['explanation'].isNotEmpty) ...[
              const Divider(),
              Text("Açıklama: ${mistake['explanation']}",
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }
}
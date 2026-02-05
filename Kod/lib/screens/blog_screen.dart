// lib/screens/blog_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase kütüphanesi

// -----------------------------------------------------------------------------
// 1. ADIM: VERİ MODELİ (GÜNCELLENDİ)
// -----------------------------------------------------------------------------
class BlogPost {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final DateTime publishedAt;
  final String readTime;

  BlogPost({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.publishedAt,
    required this.readTime,
  });

  // Firebase'den gelen veriyi (DocumentSnapshot) bizim sınıfımıza çeviren fabrika
  factory BlogPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return BlogPost(
      id: doc.id,
      title: data['title'] ?? 'Başlıksız',
      category: data['category'] ?? 'Genel',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150', // Resim yoksa placeholder
      // Timestamp'i DateTime'a çeviriyoruz
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readTime: data['readTime'] ?? '3 dk',
    );
  }
}

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  // --- STATE DEĞİŞKENLERİ ---
  String _selectedCategory = "Tümü"; 
  bool _isDescending = true; // True: En Yeni -> En Eski

  // Kategoriler Listesi
  final List<String> _categories = ["Tümü", "Rehberlik", "Ders Taktikleri", "Haberler", "Motivasyon"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("DUS Rehberi", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isDescending = !_isDescending;
              });
            },
            icon: Icon(
              _isDescending ? Icons.sort_rounded : Icons.history_rounded,
              color: Colors.blue,
            ),
            tooltip: _isDescending ? "En Yeni" : "En Eski",
          ),
          const SizedBox(width: 8),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // --- KATEGORİ FİLTRESİ ---
          Container(
            height: 60,
            color: Colors.white, 
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),

          // --- FIREBASE STREAM BUILDER ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Firebase'den 'blog_posts' koleksiyonunu dinliyoruz
              // Not: Sıralamayı (orderBy) burada yapıyoruz
              stream: FirebaseFirestore.instance
                  .collection('blog_posts')
                  .orderBy('publishedAt', descending: _isDescending)
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Hata Durumu
                if (snapshot.hasError) {
                  return Center(child: Text("Bir hata oluştu: ${snapshot.error}"));
                }

                // 2. Yükleniyor Durumu
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 3. Veri Geldiyse İşle
                final docs = snapshot.data!.docs;
                
                // Gelen dokümanları BlogPost listesine çevir
                List<BlogPost> allPosts = docs.map((doc) => BlogPost.fromFirestore(doc)).toList();

                // 4. Kategori Filtrelemesi (Client tarafında yapıyoruz)
                List<BlogPost> filteredPosts = allPosts;
                if (_selectedCategory != "Tümü") {
                  filteredPosts = allPosts.where((post) => post.category == _selectedCategory).toList();
                }

                // 5. Liste Boşsa
                if (filteredPosts.isEmpty) {
                  return _buildEmptyState();
                }

                // 6. Listeyi Çiz
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    return _buildBlogCard(filteredPosts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Blog Kartı Tasarımı (Değişmedi)
  Widget _buildBlogCard(BlogPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resim Alanı
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: NetworkImage(post.imageUrl),
                fit: BoxFit.cover,
                // Resim yüklenemezse hata vermesin diye:
                onError: (exception, stackTrace) {
                  debugPrint("RESİM HATASI: $exception"); // <-- Konsola hatayı basar
                }, 
              ),
            ),
            // Resim yüklenirken veya hata varsa gösterilecek ikon (opsiyonel)
            child: post.imageUrl.isEmpty 
              ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)) 
              : null,
          ),
          // İçerik
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        post.category,
                        style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          "${post.publishedAt.day}/${post.publishedAt.month}/${post.publishedAt.year}",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.menu_book, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text("Okuma Süresi: ${post.readTime}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const Spacer(),
                    const Text("Oku", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Bu kategoride henüz yazı yok.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
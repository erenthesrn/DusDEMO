// lib/screens/edit_profile_page.dart
import 'dart:ui'; // BackdropFilter ve ImageFilter için gerekli
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> with SingleTickerProviderStateMixin {
  // Controllerlar
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Göz işaretlerinin durumu
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;

  // Animasyon Kontrolcüsü
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Giriş Animasyonu Ayarları
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(); // Animasyonu başlat
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? "";
      _nameController.text = user.displayName ?? "";
      
      if (user.displayName == null || user.displayName!.isEmpty) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
          if (doc.exists && mounted) {
            setState(() {
               _nameController.text = doc['name'];
            });
          }
        });
      }
    }
  }

  // --- YARDIMCI FONKSİYONLAR ---
  bool _isPasswordStrong(String password) {
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasMinLength = password.length >= 8;
    return hasUppercase && hasDigits && hasMinLength;
  }

  Future<void> _updateName() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İsim güncellendi! ✅")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty || 
        _newPasswordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm şifre alanlarını doldurun.")));
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yeni şifreler birbiriyle uyuşmuyor! ❌"), backgroundColor: Colors.red)
      );
      return;
    }

    if (!_isPasswordStrong(_newPasswordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifre Yetersiz: En az 1 BÜYÜK HARF ve 1 RAKAM içermelidir! ⚠️"), 
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        )
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String email = user?.email ?? "";

      AuthCredential credential = EmailAuthProvider.credential(
        email: email, 
        password: _currentPasswordController.text
      );

      await user?.reauthenticateWithCredential(credential);
      await user?.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreniz başarıyla değiştirildi! 🔒")));
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Bir hata oluştu.";
      if (e.code == 'wrong-password') errorMessage = "Mevcut şifrenizi yanlış girdiniz.";
      if (e.code == 'weak-password') errorMessage = "Şifre çok zayıf.";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    TextEditingController passwordController = TextEditingController();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hesabı Sil ⚠️", style: TextStyle(color: isDark ? const Color(0xFFE6EDF3) : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Bu işlem geri alınamaz. Güvenliğiniz için lütfen şifrenizi girin:", 
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black87)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: const InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Vazgeç")
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("Onayla ve Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && passwordController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        User? user = FirebaseAuth.instance.currentUser;
        String email = user?.email ?? "";

        AuthCredential credential = EmailAuthProvider.credential(
          email: email, 
          password: passwordController.text
        );
        await user?.reauthenticateWithCredential(credential);

        await FirebaseFirestore.instance.collection('users').doc(user?.uid).delete();
        await user?.delete();

        if (mounted) {
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (context) => const LoginPage()),
             (route) => false,
           );
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hesabınız kalıcı olarak silindi. Hoşçakalın! 👋")));
        }
      } on FirebaseAuthException catch (e) {
        String err = "Bir hata oluştu.";
        if (e.code == 'wrong-password') err = "Şifreyi yanlış girdiniz.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- TEMA VE RENK AYARLARI ---
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1E293B);
    final Color sectionHeaderColor = isDark ? const Color(0xFF448AFF) : const Color(0xFF0D47A1);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      appBar: AppBar(
        title: Text("Profili Düzenle", 
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent, // Glass effect arkası için transparan
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              // --- DÜZELTİLEN KISIM: GLOW EFEKTİ ---
              if (isDark)
                Positioned(
                  top: -100, right: -100,
                  child: ImageFiltered( // HATA BURADA DÜZELTİLDİ
                    imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF448AFF).withOpacity(0.1),
                      ),
                    ),
                  ),
                ),

              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 120, 24, 40), // AppBar için üstten boşluk
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        
                        // --- 0. PREMIUM AVATAR ALANI ---
                        _buildPremiumAvatar(isDark),
                        const SizedBox(height: 40),

                        // --- 1. KİŞİSEL BİLGİLER KARTI ---
                        Align(alignment: Alignment.centerLeft, child: Text("Kişisel Bilgiler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sectionHeaderColor))),
                        const SizedBox(height: 12),
                        _buildGlassCard(
                          isDark: isDark,
                          children: [
                            _buildTextField(
                              controller: _emailController,
                              label: "E-posta",
                              icon: Icons.email_outlined,
                              isReadOnly: true,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nameController,
                              label: "Ad Soyad",
                              icon: Icons.person_outline,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 20),
                            _buildGradientButton(
                              text: "İsmi Güncelle",
                              onTap: _updateName,
                              colors: isDark ? [const Color(0xFF448AFF), const Color(0xFF2962FF)] : [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // --- 2. GÜVENLİK KARTI ---
                        Align(alignment: Alignment.centerLeft, child: Text("Güvenlik & Şifre", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sectionHeaderColor))),
                        const SizedBox(height: 12),
                        _buildGlassCard(
                          isDark: isDark,
                          children: [
                            _buildTextField(
                              controller: _currentPasswordController,
                              label: "Mevcut Şifre",
                              icon: Icons.lock_outline,
                              isDark: isDark,
                              obscureText: _obscureCurrent,
                              onEyeTap: () => setState(() => _obscureCurrent = !_obscureCurrent),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _newPasswordController,
                              label: "Yeni Şifre",
                              icon: Icons.vpn_key,
                              isDark: isDark,
                              obscureText: _obscureNew,
                              onEyeTap: () => setState(() => _obscureNew = !_obscureNew),
                              hint: "En az 1 büyük harf ve rakam",
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: "Yeni Şifre (Tekrar)",
                              icon: Icons.vpn_key_outlined,
                              isDark: isDark,
                              obscureText: _obscureConfirm,
                              onEyeTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            const SizedBox(height: 20),
                            _buildGradientButton(
                              text: "Şifreyi Değiştir",
                              onTap: _changePassword,
                              colors: [const Color(0xFFFF9800), const Color(0xFFF57C00)], // Turuncu Gradient
                              shadowColor: Colors.orange.withOpacity(0.4),
                            ),
                          ],
                        ),

                        const SizedBox(height: 50),

                        // --- SİLME BUTONU ---
                        TextButton.icon(
                          onPressed: _deleteAccount,
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          label: const Text("Hesabımı Kalıcı Olarak Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            backgroundColor: Colors.red.withOpacity(0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // --- PREMIUM WIDGET PARÇALARI ---

  Widget _buildPremiumAvatar(bool isDark) {
    String initials = "U";
    if (_nameController.text.isNotEmpty) {
      initials = _nameController.text.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase();
    }

    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF448AFF).withOpacity(0.5) : const Color(0xFF0D47A1).withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0xFF448AFF).withOpacity(0.3) : Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5
          )
        ]
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 36, 
            fontWeight: FontWeight.bold, 
            color: isDark ? const Color(0xFF448AFF) : const Color(0xFF0D47A1)
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required List<Widget> children, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22).withOpacity(0.7) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isReadOnly = false,
    bool obscureText = false,
    VoidCallback? onEyeTap,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        obscureText: obscureText,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontSize: 13),
          labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
          prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.grey.shade500),
          suffixIcon: onEyeTap != null 
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: isDark ? Colors.white54 : Colors.grey),
                onPressed: onEyeTap,
              ) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text, 
    required VoidCallback onTap, 
    required List<Color> colors,
    Color? shadowColor
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? colors.first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6)
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(
              text, 
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
          ),
        ),
      ),
    );
  }
}
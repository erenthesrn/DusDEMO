// lib/screens/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:dus_app_1/Fish.dart'; 

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose(); 
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen e-posta adresinizi girin."), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Bağlantı Gönderildi 📨"),
            content: const Text("E-posta adresinize şifre sıfırlama bağlantısı gönderildi. Lütfen spam kutunuzu da kontrol etmeyi unutmayın."),
            actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("Tamam"))],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Bir hata oluştu.";
      if (e.code == 'user-not-found') errorMessage = "Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı.";
      else if (e.code == 'invalid-email') errorMessage = "Geçersiz e-posta formatı.";
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ZORUNLU LIGHT MODE
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0D47A1),
      scaffoldBackgroundColor: const Color.fromARGB(255, 224, 247, 250),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0D47A1),
        secondary: Color(0xFF00BFA5),
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIconColor: Colors.grey[600],
      ),
    );

    return Theme(
      data: lightTheme,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 224, 247, 250),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 224, 247, 250),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (context) => Icon(Fish.fish_svgrepo_com, size: 100, color: Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(height: 24),
                
                Builder(
                  builder: (context) => Text('Şifrenizi mi unuttunuz?', 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
                  ),
                ),
                const SizedBox(height: 12),
                
                const Text(
                  'Hesabınıza bağlı e-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
                  style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 32),

                // Email Input (Artık beyaz arka planlı)
                TextField(
                  controller: _emailController, 
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta Adresi', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 32),

                // Gönder Butonu
                SizedBox(
                  height: 50,
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Text('Bağlantı Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
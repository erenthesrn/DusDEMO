// lib/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth eklendi
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'home_screen.dart'; // Ana sayfaya yönlendirmek için
import 'guest_home_page.dart'; // <-- Bunu ekle

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // ===========================================================================
  // ||  🔥 GÜNCELLENMİŞ GİRİŞ MANTIĞI                                        ||
  // ===========================================================================
  void _handleLogin() async {
    // 1. Klavyeyi kapat
    FocusScope.of(context).unfocus();

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // 2. Boş alan kontrolü
    if (email.isEmpty || password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun."), backgroundColor: Colors.orange),
      );
      return;
    }

    // 3. Yükleniyor başlat
    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 ADIM 1: Firebase'e Giriş Yap
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔥 ADIM 2: E-posta Doğrulanmış mı Kontrol Et
      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        // EĞER ONAYLANMAMIŞSA:
        await FirebaseAuth.instance.signOut(); // Hemen çıkış yap (İçeri alma)
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("E-posta Onayı Gerekli 📧"),
              content: const Text("Giriş yapabilmek için lütfen e-posta adresinize gönderilen onay linkine tıklayın."),
              actions: [
                TextButton(
                  onPressed: () async {
                     // İsteğe bağlı: Tekrar mail gönder butonu
                     // await user.sendEmailVerification(); 
                     Navigator.of(context).pop();
                  },
                  child: const Text("Tamam"),
                ),
              ],
            ),
          );
        }
      } else {
        // EĞER ONAYLANMIŞSA (veya null değilse):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Giriş Başarılı!"), backgroundColor: Colors.green),
          );

          // Ana Sayfaya Yönlendir
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      // 🔥 HATA YÖNETİMİ
      String errorMessage = "Giriş başarısız.";
      
      if (e.code == 'user-not-found') {
        errorMessage = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Şifre hatalı.";
      } else if (e.code == 'invalid-credential') {
        errorMessage = "E-posta veya şifre hatalı.";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Çok fazla deneme yaptınız. Lütfen biraz bekleyin.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Her durumda yükleniyor simgesini durdur
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 247, 250),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO KISMI

                Padding(
                  padding: const EdgeInsets.only(top: 30.0), 
                  child: Image.asset(
                    'assets/images/logo.png', 
                    height: 150, 
                  ),
                ),
                
                // --- YAZIYI YUKARI ÇEKEN KOD (Transform) ---
                Transform.translate(
                  offset: const Offset(0, -20), 
                  child: Text(
                    'DUS Asistanı', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).primaryColor
                    )
                  ),
                ),
                
                const SizedBox(height: 8),

                // 🔥 ATATÜRK SÖZÜ VE İMZASI BURADA 🔥
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      const Text(
                        "“Zafer, 'zafer benimdir' diyebilenindir. Başarı ise, 'başaracağım' diye başlayıp, sonunda 'başardım' diyebilenindir.”",
                        textAlign: TextAlign.center, 
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: Colors.blueGrey, 
                          fontFamily: 'Georgia',
                          height: 1.5 // Satır aralığını biraz açtık, daha rahat okunur
                        )
                      ),
                      const SizedBox(height: 10),
                      // İMZA KISMI (SAĞA YASLI)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "- Mustafa Kemal ATATÜRK",
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).primaryColor, // Temanın ana rengiyle uyumlu
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40), // Boşluğu biraz azalttık çünkü söz alanı büyüdü
                
                // Email Input
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta Adresi', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 20),
                
                // Şifre Input
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                    ),
                  ),
                ),

                // --- ŞİFREMİ UNUTTUM ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage()));
                    },
                    child: const Text('Şifremi Unuttum?'),
                  ),
                ),
                const SizedBox(height: 24),

                // --- GİRİŞ BUTONU ---
                SizedBox(
                  height: 56, 
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        )
                      : const Text(
                          'Giriş Yap', 
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                  ),
                ),

                const SizedBox(height: 32),

                // --- VEYA ÇİZGİSİ ---
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("veya", style: TextStyle(color: Colors.grey[500])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 24),

                // --- MİSAFİR BUTONU ---
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      // Misafir girişini de Home'a yönlendirebilirsin veya böyle bırakabilirsin
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const GuestHomePage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Misafir olarak devam et',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).primaryColor
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // --- KAYIT OL ALANI ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Üye değil misiniz?', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                      },
                      child: Text('Kayıt Ol', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
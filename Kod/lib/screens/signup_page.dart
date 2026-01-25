// lib/screens/signup_page.dart
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar sayesinde otomatik "Geri Dön" oku çıkar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor), // Geri okunun rengi
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 Text('Yeni Hesap Oluştur', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                 const SizedBox(height: 8),
                 const Text('DUS hazırlık sürecinde aramıza katılın.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                 const SizedBox(height: 32),
                
                // Ad Soyad Input
                const TextField(
                  decoration: InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 20),

                // Email Input
                const TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'E-posta Adresi', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 20),

                // Şifre Input
                TextField(
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
                 const SizedBox(height: 20),

                 // Şifre Tekrar Input
                TextField(
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () { setState(() { _isConfirmPasswordVisible = !_isConfirmPasswordVisible; }); },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Kayıt Ol Butonu
                ElevatedButton(
                  onPressed: () {
                     // Kayıt işlemi burada yapılacak
                  },
                  child: const Text('Kayıt Ol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// lib/screens/forgot_password_page.dart
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_reset, size: 60, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 24),
              Text('Şifrenizi mi unuttunuz?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 12),
              const Text(
                'Hesabınıza bağlı e-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Email Input
              const TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'E-posta Adresi', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 32),

              // Gönder Butonu
              ElevatedButton(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sıfırlama bağlantısı gönderildi.")));
                },
                child: const Text('Bağlantı Gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
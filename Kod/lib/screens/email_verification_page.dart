import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'onboarding_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? countdownTimer;
  Timer? checkVerifiedTimer;
  int countdown = 90;

  @override
  void initState() {
    super.initState();

    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      startCountdownTimer();
      
      checkVerifiedTimer = Timer.periodic(
        const Duration(seconds: 3), 
        (_) => checkEmailVerified(),
      );
    }
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      countdownTimer?.cancel();
      checkVerifiedTimer?.cancel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta başarıyla doğrulandı! Yönlendiriliyorsunuz... 🚀'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingPage()), 
          (route) => false,
        );
      }
    }
  }

  void startCountdownTimer() {
    setState(() {
      canResendEmail = false;
      countdown = 90;
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          canResendEmail = true;
          countdownTimer?.cancel();
        }
      });
    });
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      startCountdownTimer();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğrulama maili tekrar gönderildi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> cancelAndReturnToLogin() async {
    countdownTimer?.cancel();
    checkVerifiedTimer?.cancel();
    
    await FirebaseAuth.instance.signOut();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()), 
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    checkVerifiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "E-posta adresi alınamadı";

    // DÜZENLEME: Theme widget'ı ile sarmalayarak bu sayfayı zorla Light Mode yapıyoruz.
    return Theme(
      data: ThemeData.light(), // Bu satır sayesinde altındaki tüm textler siyah olur
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'E-posta Doğrulama',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                
                const Icon(
                  Icons.mark_email_read_outlined, 
                  size: 100, 
                  color: Colors.blue
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Doğrulama Maili Gönderildi! 📧',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  '$email adresine bir doğrulama bağlantısı gönderdik.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Lütfen mail kutunuzu (gelen kutusu veya spam/gereksiz klasörünü) kontrol edin ve gelen linke tıklayın.\n\nSistem otomatik olarak onayınızı algılayacaktır...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: canResendEmail ? sendVerificationEmail : null,
                    icon: const Icon(Icons.email),
                    label: Text(
                      canResendEmail 
                        ? 'Tekrar Mail Gönder' 
                        : 'Tekrar Gönder (${countdown}s)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                TextButton(
                  onPressed: cancelAndReturnToLogin,
                  child: const Text(
                    'Vazgeç ve Girişe Dön',
                    style: TextStyle(color: Colors.grey),
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
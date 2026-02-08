// lib/screens/focus_screen.dart

import 'dart:ui'; // 🔥 CAM EFEKTİ VE BLUR İÇİN
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart'; // Premium Font
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/focus_service.dart'; 
import '../services/theme_provider.dart'; // Tema kontrolü

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

// 🔥 TickerProviderStateMixin eklendi (Animasyon için)
class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  final FocusService _focusService = FocusService.instance;
  late AnimationController _pulseController; // Nefes alma efekti için

  @override
  void initState() {
    super.initState();
    // Nefes alma animasyonu (2 saniyede bir büyüyüp küçülecek)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tema verilerini al
    final themeProvider = ThemeProvider.instance;
    final isDark = themeProvider.isDarkMode;

    // --- RENK PALETİ ---
    // Arka plan gradienti
    final bgGradient = isDark 
      ? const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF000000)]) // Derin Uzay
      : const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFE0F7FA), Color(0xFFF0F4C3)]); // Ferah Gün Işığı

    // Vurgu Rengi (Mavi veya Yeşil)
    final accentColor = isDark ? const Color(0xFF448AFF) : const Color(0xFF1565C0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      extendBodyBehindAppBar: true, // Appbar arkasına background uzasın
      appBar: AppBar(
        title: Text("Odak Modu 🎯", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. KATMAN: Arka Plan Gradient
          Container(decoration: BoxDecoration(gradient: bgGradient)),

          // 2. KATMAN: İçerik
          AnimatedBuilder(
            animation: _focusService, // Servisi dinliyoruz
            builder: (context, child) {
              
              double percent = _focusService.totalTimeInSeconds > 0
                  ? (_focusService.remainingSeconds / _focusService.totalTimeInSeconds)
                  : 0.0;

              return SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // --- SAYAÇ (GLOW EFFECT) ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Arkadaki Nefes Alan Işık (Sadece çalışırken)
                        if (_focusService.isRunning)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 280 + (_pulseController.value * 20),
                                height: 280 + (_pulseController.value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(isDark ? 0.3 : 0.2),
                                      blurRadius: 50,
                                      spreadRadius: 10,
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        
                        // Ana Sayaç
                        CircularPercentIndicator(
                          radius: 140.0,
                          lineWidth: 18.0, // Biraz kalınlaştırdık
                          animation: false, // Manuel animasyon kullanıyoruz akıcı olsun diye
                          percent: percent.clamp(0.0, 1.0),
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                          progressColor: _focusService.remainingSeconds < 60 ? Colors.redAccent : accentColor,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 🔥 HATA DÜZELTİLDİ: robotoMono kullanıldı
                              Text(
                                _formatTime(_focusService.remainingSeconds),
                                style: GoogleFonts.robotoMono(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 64.0,
                                  color: textColor,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                child: Text(
                                  _focusService.isRunning ? "ODAKLANIYOR..." : (_focusService.isPaused ? "DURAKLATILDI" : "HAZIR"),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.0,
                                    color: accentColor,
                                    letterSpacing: 1.5
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // --- HIZLI SEÇİM (GLASS) ---
                    _buildGlassContainer(
                      isDark: isDark,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Hızlı Süre Seçimi", 
                              style: TextStyle(fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7))),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTimeChip("Pomodoro", 25, isDark, accentColor),
                              _buildTimeChip("Etüt", 50, isDark, accentColor),
                              _buildTimeChip("Blok", 60, isDark, accentColor),
                              _buildCustomChip(isDark, textColor),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- KONTROL BUTONLARI (PREMIUM) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_focusService.isRunning && !_focusService.isPaused)
                          _buildPlayButton(Icons.play_arrow_rounded, "BAŞLAT", accentColor, _focusService.startTimer)
                        else if (_focusService.isRunning)
                          _buildPlayButton(Icons.pause_rounded, "DURAKLAT", Colors.orange, _focusService.pauseTimer)
                        else if (_focusService.isPaused)
                          _buildPlayButton(Icons.play_arrow_rounded, "DEVAM ET", Colors.green, _focusService.resumeTimer),
                        
                        const SizedBox(width: 24),
                        
                        // Reset butonu (Sadece süre değişmişse görünür)
                        if (_focusService.remainingSeconds != _focusService.totalTimeInSeconds)
                          _buildSecondaryButton(Icons.refresh_rounded, isDark, _focusService.resetTimer),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR (PREMIUM DESIGN) ---

  // 1. Buzlu Cam Kutusu
  Widget _buildGlassContainer({required Widget child, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
          ),
          child: child,
        ),
      ),
    );
  }

  // 2. Süre Seçim Çipi
  Widget _buildTimeChip(String label, int minutes, bool isDark, Color activeColor) {
    bool isSelected = (_focusService.totalTimeInSeconds == minutes * 60);
    return GestureDetector(
      onTap: () => _focusService.setDuration(minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : (isDark ? Colors.white.withOpacity(0.1) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: isSelected 
            ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] 
            : null
        ),
        child: Column(
          children: [
            Text("$minutes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87))),
            Text("dk", style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  // 3. Özel Süre Çipi
  Widget _buildCustomChip(bool isDark, Color textColor) {
    return GestureDetector(
      onTap: _showDurationPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.edit_rounded, size: 20, color: textColor.withOpacity(0.7)),
            Text("Özel", style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  // 4. Ana Oynatma Butonu (Büyük ve Glowlu)
  Widget _buildPlayButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  // 5. İkincil Buton (Glass Icon)
  Widget _buildSecondaryButton(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60, width: 60,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black54),
      ),
    );
  }

  // --- MANTIK KISIMLARI (DEĞİŞMEDİ) ---

  void _showDurationPicker() {
    Duration initialDuration = Duration(seconds: _focusService.totalTimeInSeconds);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Süre Seç", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: initialDuration,
                  onTimerDurationChanged: (Duration newDuration) {
                    if (newDuration.inSeconds > 0) {
                      _focusService.setDuration(newDuration.inMinutes);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  String? _selectedLangCode;
  bool _isStarting = false;

  final List<Map<String, dynamic>> _languages = [
    {"code": "en", "label": "English 🇺🇸"},
    {"code": "ar", "label": "العربية 🇸🇦"},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    setState(() => _isStarting = true);
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final seenLanding = prefs.getBool('seenLandingPage') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        seenLanding ? '/main' : '/landing',
      );
    }
  }

  void _onLangSelected(String code) {
    context.setLocale(Locale(code));
    setState(() => _selectedLangCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale; // keep localization active

    return Scaffold(
      // ---------- NEW WHITE BACKGROUND ----------
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---------- UPDATED LOGO ----------
              SizedBox(
                height: 300,
                width: 300,
                child: Image.asset(
                  'assets/images/Screenshot_2025-03-24_213038-removebg-preview.png', // ← replace with your new image
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              // ---------- Language Dropdown ----------
              // ---------- Language Selection Buttons ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _languages.map((lang) {
                    final isSelected = _selectedLangCode == lang['code'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton(
                        onPressed: () => _onLangSelected(lang['code']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? const Color(0xFF18AEAC) : Colors.white,
                          foregroundColor: isSelected ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          lang['label'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),


              const SizedBox(height: 40),

              // ---------- Start Button ----------
              if (_selectedLangCode != null && !_isStarting)
                ElevatedButton.icon(
                  onPressed: _startApp,
                  icon: const Icon(Icons.play_arrow),
                  label: Text("start_app".tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18AEAC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

              // ---------- Loading ----------
              if (_isStarting) ...[
                const SizedBox(height: 24),
                Text(
                  "please_wait".tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    color:  Color(0xFF18AEAC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: Colors.black87),
              ]
            ],
          ),
        ),
      ),
    );
  }
}


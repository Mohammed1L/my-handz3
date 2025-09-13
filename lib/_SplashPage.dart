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
    setState(() {
      _isStarting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final seenLanding = prefs.getBool('seenLandingPage') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        seenLanding ? '/phoneVerification' : '/landing',
      );
    }
  }

  void _onLangSelected(String code) {
    final locale = Locale(code);
    context.setLocale(locale);
    setState(() => _selectedLangCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FA),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---------- Logo ----------
              SizedBox(
                height: 250,
                width: 250,
                child: Image.asset(
                  'assets/images/Screenshot_2025-03-24_213038-removebg-preview.png',
                ),
              ),
              const SizedBox(height: 30),

              // ---------- Language Dropdown ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF007EA7), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLangCode,
                      hint: Text("change_language".tr()),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onChanged: (value) => _onLangSelected(value!),
                      items: _languages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Text(lang['label'], style: const TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ---------- Start Button ----------
              if (_selectedLangCode != null && !_isStarting)
                ElevatedButton.icon(
                  onPressed: _startApp,
                  icon: const Icon(Icons.play_arrow),
                  label: Text("start_app".tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007EA7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

              // ---------- Loading ----------
              if (_isStarting) ...[
                const SizedBox(height: 24),
                Text(
                  "please_wait".tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF007EA7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: Color(0xFF007EA7)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

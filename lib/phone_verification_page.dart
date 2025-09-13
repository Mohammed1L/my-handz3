import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'otp_verification_page.dart';
import 'dart:ui' as ui;

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  _PhoneVerificationPageState createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _errorMessage;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool _isRTL(Locale locale) {
    return ['ar', 'fa', 'he', 'ur'].contains(locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSendCode() async {
    String name = _nameController.text.trim();
    String phoneNumber = _phoneController.text.trim();

    if (name.isEmpty || phoneNumber.isEmpty || phoneNumber.length != 9 || !phoneNumber.startsWith('5')) {
      setState(() {
        _errorMessage = name.isEmpty
            ? "name_empty".tr()
            : phoneNumber.isEmpty
            ? "phone_empty".tr()
            : !phoneNumber.startsWith('5')
            ? "phone_start".tr()
            : "phone_length".tr();
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);

    String fullPhoneNumber = '+966$phoneNumber';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _errorMessage = 'Verification failed: ${e.message}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => OTPVerificationPage(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending code: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isRTL = _isRTL(locale);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB2DFDB), Color(0xFF007EA7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Icon(Icons.phone_android, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Text(
                  "enter_name_phone".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007EA7),
                  ),
                ),
                const SizedBox(height: 30),

                // ---------------- Name Field ----------------
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "name".tr(),
                    labelStyle: const TextStyle(color: Colors.grey),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF007EA7)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF007EA7), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // ---------------- Phone Field ----------------
                Directionality(
                  textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  textDirection: ui.TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: "phone_number".tr(),
                    labelStyle: const TextStyle(color: Colors.grey),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF007EA7)),
                    prefixText: context.locale.languageCode == 'en' ? '+966 ' : null,
                    suffixText: context.locale.languageCode == 'ar' ? ' 966+' : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF007EA7), width: 1.5),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value.isNotEmpty && (!value.startsWith('5') || value.length > 9)) {
                        _errorMessage = !value.startsWith('5')
                            ? "phone_start".tr()
                            : "phone_length".tr();
                      } else {
                        _errorMessage = null;
                      }
                    });
                  },
                ),
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _validateAndSendCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: const Color(0xFF007EA7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "send_code".tr(),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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

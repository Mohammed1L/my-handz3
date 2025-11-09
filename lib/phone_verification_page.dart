import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'otp_verification_page.dart';
import 'main_page.dart';
import 'dart:ui' as ui;

/// Normalize Saudi numbers to E.164: +9665XXXXXXXX
String toE164KSA(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), ''); // keep numbers only
  if (digits.isEmpty) return '+966';
  if (digits.startsWith('966')) return '+$digits';
  if (digits.startsWith('0')) return '+966${digits.substring(1)}';
  if (digits.startsWith('5')) return '+966$digits';
  // Fallback: assume already E.164 if user typed +...
  if (raw.trim().startsWith('+')) return raw.trim();
  return '+966$digits';
}

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
  bool _sending = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool _isRTL(Locale locale) =>
      ['ar', 'fa', 'he', 'ur'].contains(locale.languageCode);

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

  String? _validateInputs() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (name.isEmpty) return "name_empty".tr();
    if (phone.isEmpty) return "phone_empty".tr();
    if (!phone.startsWith('5') && !phone.startsWith('05') && !phone.startsWith('9665')) {
      return "phone_start".tr(); // expects a local 5XXXXXXXX or 05XXXXXXXX
    }
    // Accept 9 local digits (5XXXXXXXX) or 10 with leading 0 (05XXXXXXXX)
    final local = phone.startsWith('0') ? phone.substring(1) : phone;
    if (local.length != 9) return "phone_length".tr();
    return null;
  }

  Future<void> _sendCode() async {
    final error = _validateInputs();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());

    final fullPhone = toE164KSA(_phoneController.text);

    setState(() {
      _sending = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const MainPage(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 400),
              ),
                  (route) => false,
            );
          } catch (e) {
            // If silent sign-in fails, user still proceeds to OTP screen via codeSent.
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          String msg;
          switch (e.code) {
            case 'invalid-phone-number':
              msg = "invalid_phone".tr();
              break;
            case 'too-many-requests':
              msg = "too_many_requests".tr();
              break;
            case 'network-request-failed':
              msg = "network_error".tr();
              break;
            case 'quota-exceeded':
              msg = "verification_failed".tr() + " (quota-exceeded)";
              break;
            default:
              msg = '${"verification_failed".tr()}: ${e.message ?? e.code}';
          }
          setState(() {
            _sending = false;
            _errorMessage = msg;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _sending = false);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => OTPVerificationPage(
                phoneNumber: _phoneController.text.trim(),
                verificationId: verificationId,
                forceResendToken: resendToken,
              ),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() {
        _sending = false;
        _errorMessage = 'Error: $e';
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
                      colors: [Color(0xFF18AEAC), Color(0xFF18AEAC)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Image.asset(
                    'assets/images/smartphone.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
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

                // Name
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "name".tr(),
                    labelStyle: const TextStyle(color: Colors.grey),
                    floatingLabelStyle:
                    const TextStyle(color: Color(0xFF007EA7)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Color(0xFF007EA7), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Phone (LTR digits in both locales)
                Directionality(
                  textDirection:
                  isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 9, // local KSA 5XXXXXXXX (9 digits)
                    textDirection: ui.TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: "phone_number".tr(),
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle:
                      const TextStyle(color: Color(0xFF007EA7)),
                      prefixText:
                      context.locale.languageCode == 'en' ? '+966 ' : null,
                      suffixText:
                      context.locale.languageCode == 'ar' ? ' 966+' : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: Color(0xFF007EA7), width: 1.5),
                      ),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
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

                const SizedBox(height: 30),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF007EA7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      "send_code".tr(),
                      style: const TextStyle(
                          fontSize: 18, color: Colors.white),
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

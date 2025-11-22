import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'dart:ui' as ui;

/// Normalize Saudi numbers to E.164: +9665XXXXXXXX
String toE164KSA(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '+966';
  if (digits.startsWith('966')) return '+$digits';
  if (digits.startsWith('0')) return '+966${digits.substring(1)}';
  if (digits.startsWith('5')) return '+966$digits';
  if (raw.trim().startsWith('+')) return raw.trim();
  return '+966$digits';
}

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? forceResendToken;

  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.forceResendToken,
  });

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _verifying = false;
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  // Resend cooldown
  static const int _cooldownSec = 30;
  Timer? _resendTimer;
  int _secondsLeft = 0;

  String _verificationId = '';
  int? _forceResendToken; // <-- keep latest token

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _forceResendToken = widget.forceResendToken;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final smsCode = _codeController.text.trim();
    if (smsCode.length != 6) {
      setState(() => _errorMessage = "invalid_otp".tr());
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainPage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _verifying = false;
        _errorMessage = e.code == 'invalid-verification-code'
            ? "invalid_otp".tr()
            : '${"verification_failed".tr()}: ${e.message ?? e.code}';
      });
    } catch (e) {
      setState(() {
        _verifying = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _startCooldown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _cooldownSec);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resendCode() async {
    if (_secondsLeft > 0) return;

    final fullPhone = toE164KSA(widget.phoneNumber);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _forceResendToken, // <-- use latest
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          setState(() {
            _errorMessage =
            '${"verification_failed".tr()}: ${e.message ?? e.code}';
          });
        },
        codeSent: (String newVerificationId, int? newToken) {
          setState(() {
            _verificationId = newVerificationId;
            _forceResendToken = newToken; // <-- update token
            _errorMessage = null;
          });
          _startCooldown();
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFB2DFDB), Color(0xFF007EA7)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(24),
                      child:
                      const Icon(Icons.chat, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "enter_otp".tr(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007EA7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: '${'code_sent_to'.tr()} ',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        children: [
                          WidgetSpan(
                            child: Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: Text(
                                toE164KSA(widget.phoneNumber),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      textDirection: Directionality.of(context),
                    ),
                    const SizedBox(height: 40),

                    // OTP field
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: "otp_label".tr(),
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle:
                        const TextStyle(color: Color(0xFF007EA7)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        counterText: "",
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF007EA7), width: 1.5),
                        ),
                      ),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                    ),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Verify
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifying ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007EA7),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _verifying
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          "verify".tr(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Resend
                    TextButton(
                      onPressed: _secondsLeft > 0 ? null : _resendCode,
                      child: Text(
                        _secondsLeft > 0
                            ? "${'resend_code_in'.tr()} $_secondsLeft s"
                            : "resend_code".tr(),
                        style: TextStyle(
                          color: _secondsLeft > 0
                              ? Colors.grey
                              : const Color(0xFF007EA7),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

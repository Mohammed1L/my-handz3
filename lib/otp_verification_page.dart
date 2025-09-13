import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _verifyCode() async {
    String smsCode = _codeController.text.trim();

    if (smsCode.isEmpty || smsCode.length < 6) {
      setState(() {
        _errorMessage = "Enter a valid 6-digit code";
      });
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
            (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = "invalid_otp".tr();
      });
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
                      child: const Icon(Icons.chat, size: 48, color: Colors.white),
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
                                '+966 ${widget.phoneNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      textDirection: Directionality.of(context),
                    ),


                    const SizedBox(height: 40),

                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: "otp_label".tr(),
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Color(0xFF007EA7)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        counterText: "",
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF007EA7), width: 1.5),
                        ),
                      ),
                    ),



                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007EA7),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "verify".tr(),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () {
                        // TODO: Add resend logic
                      },
                      child: Text(
                        "resend_code".tr(),
                        style: const TextStyle(
                          color: Color(0xFF007EA7),
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

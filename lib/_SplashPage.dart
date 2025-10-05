import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedLangCode;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
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
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (!seenLanding) {
      Navigator.of(context).pushReplacementNamed('/landing');
    } else if (user == null) {
      Navigator.of(context).pushReplacementNamed('/phoneVerification');
    } else {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }


  Future<void> _onLangSelected(String code) async {
    await context.setLocale(Locale(code));
    if (!mounted) return;
    setState(() => _selectedLangCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return Scaffold(
      body: Stack(
        children: [
          // -------- Moving Gradient Background --------
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade100,
                      Colors.white,
                      Colors.teal.shade50,
                    ],
                    stops: [
                      0.2 + 0.1 * sin(_controller.value * 2 * pi),
                      0.5,
                      0.8 + 0.1 * cos(_controller.value * 2 * pi),
                    ],
                  ),
                ),
              );
            },
          ),

          // -------- Floating Blobs --------
          ...List.generate(6, (i) {
            final random = Random(i);
            final size = 120.0 + random.nextInt(80);
            final dx = random.nextDouble();
            final dy = random.nextDouble();

            return AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final angle = 2 * pi * _controller.value + i;
                final offsetX = sin(angle + i) * 60 * (0.5 + dx);
                final offsetY = cos(angle + i) * 60 * (0.5 + dy);

                return Positioned(
                  left: MediaQuery.of(context).size.width * dx + offsetX - size / 2,
                  top: MediaQuery.of(context).size.height * dy + offsetY - size / 2,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal.withOpacity(0.08),
                    ),
                  ),
                );
              },
            );
          }),

          // -------- Main Content --------
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Logo
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Image.asset(
                    'assets/images/Screenshot_2025-03-24_213038-removebg-preview.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),

                // Tagline
                Text(
                  "YOUR HOME, HANDLED.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                    letterSpacing: 1.2,
                  ),
                ),

                const Spacer(),

                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: _LangToggle(
                    selectedCode: _selectedLangCode,
                    onChanged: _onLangSelected,
                  ),
                ),

                const SizedBox(height: 30),

                // Start Button
                if (_selectedLangCode != null && !_isStarting)
                  SizedBox(
                    width: 220,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _startApp,
                      icon: const Icon(Icons.play_arrow),
                      label: Text("start_app".tr(),
                          style: const TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18AEAC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),

                if (_isStarting) ...[
                  const SizedBox(height: 16),
                  Text(
                    "please_wait".tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF18AEAC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: Color(0xFF18AEAC)),
                ],

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//Language Toggle
class _LangToggle extends StatefulWidget {
  final String? selectedCode;
  final ValueChanged<String> onChanged;

  const _LangToggle({
    required this.selectedCode,
    required this.onChanged,
  });

  @override
  State<_LangToggle> createState() => _LangToggleState();
}

class _LangToggleState extends State<_LangToggle>
    with SingleTickerProviderStateMixin {
  late double _t;
  late String _current;
  late AnimationController _snapController;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _current = widget.selectedCode ?? 'en';
    _t = _current == 'en' ? 0.0 : 1.0;

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _snapAnim = CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(covariant _LangToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCode != null && widget.selectedCode != _current) {
      _current = widget.selectedCode!;
      _animateTo(_current == 'en' ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final begin = _t;
    _snapController.reset();
    _snapAnim = CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutBack,
    )..addListener(() {
      setState(() {
        _t = lerpDouble(begin, target, _snapAnim.value)!;
      });
    });
    _snapController.forward();
  }

  void _commitSide(double t) {
    final chooseRight = t >= 0.5;
    final code = chooseRight ? 'ar' : 'en';
    if (_current != code) {
      _current = code;
      widget.onChanged(code);
    }
    _animateTo(chooseRight ? 1.0 : 0.0);
  }

  void _onTapLeft() => _commitSide(0.0);
  void _onTapRight() => _commitSide(1.0);
  void _onDragStart(DragStartDetails d) {}
  void _onDragUpdate(DragUpdateDetails d, double width) {
    setState(() {
      _t = (_t + d.delta.dx / (width - 12)).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails d) => _commitSide(_t);

  @override
  Widget build(BuildContext context) {
    final isEn = _t < 0.5;
    final pillAlign = Alignment(-1 + 2 * _t, 0);
    const totalWidth = 320.0;
    const totalHeight = 54.0;
    const innerPad = 6.0;
    const pillWidth = (totalWidth - innerPad * 2) / 2;
    const pillHeight = 42.0;

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: (d) => _onDragUpdate(d, totalWidth),
      onHorizontalDragEnd: _onDragEnd,
      child: Container(
        padding: const EdgeInsets.all(innerPad),
        width: totalWidth,
        height: totalHeight,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              color: Color(0x1A000000),
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: pillAlign,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Glassy blur
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          width: pillWidth,
                          height: pillHeight,
                          color: const Color(0xFF18AEAC).withOpacity(.85),
                        ),
                      ),
                      // Soft highlight stripe
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Shadow glow
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF18AEAC).withOpacity(.35),
                                blurRadius: 14,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Row(
              children: [
                _SegmentButton(
                  label: 'English 🇺🇸',
                  selected: isEn,
                  onTap: _onTapLeft,
                ),
                _SegmentButton(
                  label: 'العربية 🇸🇦',
                  selected: !isEn,
                  onTap: _onTapRight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//Single Segment
class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: selected ? Colors.white : Colors.black87,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      fontSize: 15,
    );

    return Expanded(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
            ),
          ),
          Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: textStyle,
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}

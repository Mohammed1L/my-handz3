import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui' as ui;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _textAnimController;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  int _currentPage = 0;

  final List<LandingPageSlide> _pages = [
    LandingPageSlide(
      titleKey: 'onboard.title1',
      subtitleKey: 'onboard.subtitle1',
      buttonTextKey: 'onboard.get_started',
     imagePath:  'assets/images/slide2.png',
    ),
    LandingPageSlide(
      titleKey: 'onboard.title2',
      subtitleKey: 'onboard.subtitle2',
      buttonTextKey: 'onboard.next',
      imagePath:  'assets/images/slide3.png',
    ),
    LandingPageSlide(
      titleKey: 'onboard.title3',
      subtitleKey: 'onboard.subtitle3',
      buttonTextKey: 'onboard.next',
        imagePath:  'assets/images/slide4.png'
    ),
    LandingPageSlide(
      titleKey: 'onboard.title4',
      subtitleKey: 'onboard.subtitle4',
      buttonTextKey: 'onboard.finish',
        imagePath:  'assets/images/slide5.png'
    ),
  ];


  @override
  void initState() {
    super.initState();
    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _textAnimController,
      curve: Curves.easeInOut,
    );
    _textAnimController.forward();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textAnimController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenLandingPage', true);
    Future.microtask(
            () => Navigator.of(context).pushReplacementNamed('/main'));
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _textAnimController.reset();
              _textAnimController.forward();
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 24, vertical: mediaQuery.size.height * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (_currentPage > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 20),
              SizedBox(
              height: 300,
              width: 300,
              child: Image.asset(
              page.imagePath,
              fit: BoxFit.contain,
              ),
              ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            page.titleKey.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF18AEAC),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            page.subtitleKey.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: const ExpandingDotsEffect(
                        activeDotColor: Color(0xFF18AEAC),
                        dotHeight: 10,
                        dotWidth: 10,
                        spacing: 8,
                      ),
                      onDotClicked: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18AEAC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          page.buttonTextKey.tr(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: Directionality.of(context) == ui.TextDirection.rtl ? 20 : null,
            right: Directionality.of(context) == ui.TextDirection.ltr ? 20 : null,
            child: TextButton(
              onPressed: _skip,
              child: Text(
                'onboard.skip'.tr(),
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LandingPageSlide {
  final String titleKey;
  final String subtitleKey;
  final String buttonTextKey;
  final String imagePath; // <- path to the image asset

  LandingPageSlide({
    required this.titleKey,
    required this.subtitleKey,
    required this.buttonTextKey,
    required this.imagePath,
  });
}
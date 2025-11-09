import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import '_NotificationsScreenState.dart';
import '_OrdersScreenState.dart';
import 'HomeScreenState.dart';
import '_PromotionScreenState.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late final PageController _pageController;
  final ValueNotifier<double> _navPos = ValueNotifier<double>(0);
  int _selectedIndex = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);

    _fadeController =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 300))
      ..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _pages = [
      const HomeScreen(),
      OrdersScreen(onBackToServices: () => _goTo(0)),
      PromotionScreen(onBackToServices: () => _goTo(0)),
      NotificationsScreen(onBackToHome: () => _goTo(0)),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
    _animateNavTo(index.toDouble());
    _fadeController
      ..reset()
      ..forward();
  }

  void _animateNavTo(double target) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    final anim = Tween<double>(begin: _navPos.value, end: target).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
    );

    anim.addListener(() => _navPos.value = anim.value);
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) controller.dispose();
    });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return Scaffold(
      endDrawer: const CustomDrawer(),
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Color(0xFF007EA7)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB2DFDB), Color(0xFFB2DFDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Image.asset(
          'assets/images/Screenshot_2025-03-24_213038-removebg-preview.png',
          height: 50,
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) {
            setState(() => _selectedIndex = i);
            _animateNavTo(i.toDouble());
          },
          children: _pages,
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _GlassLiquidBar(
              position: _navPos,
              onSelect: _goTo,
              specs: [
                _NavSpec(
                  icon: Icons.home_rounded,
                  label: "homeMain".tr(),
                  from: const Color(0xFF80DEEA),
                  to: const Color(0xFF4DD0E1),
                ),
                _NavSpec(
                  icon: Icons.shopping_bag_rounded,
                  label: "orders".tr(),
                  from: const Color(0xFFA5D6A7),
                  to: const Color(0xFF81C784),
                ),
                _NavSpec(
                  icon: Icons.card_giftcard_rounded,
                  label: "promotions".tr(),
                  from: const Color(0xFFCE93D8),
                  to: const Color(0xFFBA68C8),
                ),
                _NavSpec(
                  icon: Icons.notifications_rounded,
                  label: "notifications".tr(),
                  from: const Color(0xFFFFAB91),
                  to: const Color(0xFFEF6C00),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  final IconData icon;
  final String label;
  final Color from;
  final Color to;

  _NavSpec({
    required this.icon,
    required this.label,
    required this.from,
    required this.to,
  });
}

class _GlassLiquidBar extends StatefulWidget {
  final ValueNotifier<double> position;
  final void Function(int) onSelect;
  final List<_NavSpec> specs;

  const _GlassLiquidBar({
    super.key,
    required this.position,
    required this.onSelect,
    required this.specs,
  });

  @override
  State<_GlassLiquidBar> createState() => _GlassLiquidBarState();
}

class _GlassLiquidBarState extends State<_GlassLiquidBar> {
  late int _count;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _count = widget.specs.length;
  }

  int _nearestIndex(double pos) =>
      pos.clamp(0, (_count - 1).toDouble()).round();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: LayoutBuilder(builder: (context, bc) {
          final w = bc.maxWidth;
          final h = bc.maxHeight;
          final slot = w / _count;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (d) {
              final idx = (d.localPosition.dx / slot).floor();
              widget.onSelect(idx);
            },
            onHorizontalDragStart: (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (details) {
              final absPos =
              (details.localPosition.dx / slot).clamp(0, (_count - 1).toDouble());
              widget.position.value = absPos.toDouble();
              setState(() {});
            },
            onHorizontalDragEnd: (_) {
              final idx = _nearestIndex(widget.position.value);
              setState(() => _dragging = false);
              widget.onSelect(idx);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: widget.position,
                    builder: (_, pos, __) {
                      final i = pos.floor().clamp(0, _count - 1);
                      final t = pos - i;
                      final specA = widget.specs[i];
                      final specB =
                      widget.specs[math.min(i + 1, _count - 1)];
                      final blendedFrom =
                      Color.lerp(specA.from, specB.from, t)!;
                      final blendedTo =
                      Color.lerp(specA.to, specB.to, t)!;

                      final pillWidth = slot * 0.78;
                      final left =
                          pos * slot + (slot - pillWidth) / 2;
                      final pillChild = Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [blendedFrom, blendedTo],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                      );

                      if (_dragging) {
                        return Positioned(
                          left: left,
                          top: 8,
                          height: h - 16,
                          width: pillWidth,
                          child: pillChild,
                        );
                      } else {
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          left: left,
                          top: 8,
                          height: h - 16,
                          width: pillWidth,
                          child: pillChild,
                        );
                      }
                    },
                  ),

                  Row(
                    children: List.generate(_count, (i) {
                      final spec = widget.specs[i];
                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final slotWidth = c.maxWidth;
                            return Center(
                              child: ValueListenableBuilder<double>(
                                valueListenable: widget.position,
                                builder: (_, pos, __) {
                                  final dist = (pos - i).abs().clamp(0.0, 1.0);
                                  final focus = 1.0 - dist;
                                  final isNearest = focus > 0.5;
                                  final iconColor =
                                  Color.lerp(Colors.grey.shade700, Colors.white, focus)!;
                                  final textColor =
                                  Color.lerp(Colors.grey.shade700, Colors.white, focus)!;

                                  return AnimatedScale(
                                    duration: const Duration(milliseconds: 140),
                                    scale: isNearest ? 1.05 : 1.0,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 26,
                                          child: Center(
                                            child: Icon(
                                              spec.icon,
                                              size: 22,
                                              color: iconColor,
                                              shadows: isNearest
                                                  ? const [
                                                Shadow(
                                                  blurRadius: 8,
                                                  color: Color(0x33000000),
                                                  offset: Offset(0, 2),
                                                )
                                              ]
                                                  : const [],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          height: 16,
                                          width: math.max(48.0, slotWidth * 0.7),
                                          child: AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 150),
                                            curve: Curves.easeOut,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: isNearest ? FontWeight.w700 : FontWeight.w600,
                                              fontSize: 12,
                                              height: 1.0,
                                              letterSpacing: 0.1,
                                              shadows: isNearest
                                                  ? const [
                                                Shadow(
                                                  blurRadius: 6,
                                                  color: Color(0x33000000),
                                                  offset: Offset(0, 1),
                                                )
                                              ]
                                                  : const [],
                                            ),
                                            child: Opacity(
                                              opacity: 0.85 + 0.15 * focus,
                                              child: Text(
                                                spec.label,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:senior_project/service_model.dart';
import 'package:senior_project/service_providers_page.dart';
import 'package:latlong2/latlong.dart';
import 'ProviderServicesPage.dart';
import '_Chatbot.dart';
import 'LocationPickerScreen.dart';
import 'package:senior_project/widgets/provider_search_widget.dart';

const Color kPrimaryColor = Color(0xFF18AEAC);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _userName;

  LatLng? _selectedLocation;
  String _locationText = "Select your location";

  @override
  void initState() {
    super.initState();
    _loadUserName();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          //Animated Background
          const _DiagonalGradientBackdrop(),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value; // 0..1
              return Stack(
                children: [
                  _AnimatedBlob(
                    top: _lerp(-60, 10, t),
                    left: _lerp(-40, 20, t),
                    size: 220,
                    color: const Color(0xFF60E1DA).withOpacity(0.28),
                    blurSigma: 36,
                  ),
                  _AnimatedBlob(
                    top: _lerp(140, 110, t),
                    right: _lerp(-70, 0, t),
                    size: 260,
                    color: const Color(0xFFB8F3F0).withOpacity(0.34),
                    blurSigma: 32,
                  ),
                  _AnimatedBlob(
                    bottom: _lerp(-60, 0, 1 - t),
                    left: _lerp(40, -10, 1 - t),
                    size: 180,
                    color: const Color(0xFF18AEAC).withOpacity(0.20),
                    blurSigma: 28,
                  ),
                ],
              );
            },
          ),

          //Content
          SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 16),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home_rounded,
                              color: kPrimaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_userName != null && _userName!.isNotEmpty)
                                Text(
                                  "${"hello".tr()}, $_userName 👋",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                "home.available_services".tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    //Location Chip
                    const SizedBox(height: 16),
                    _FrostedCard(
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                            const LocationPickerScreen(),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration:
                            const Duration(milliseconds: 400),
                          ),
                        );
                        if (result != null && result is LatLng) {
                          setState(() {
                            _selectedLocation = result;
                            _locationText =
                            "Lat: ${result.latitude.toStringAsFixed(4)}, Lng: ${result.longitude.toStringAsFixed(4)}";
                          });
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: kPrimaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationText,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.edit_location_alt_outlined,
                              color: kPrimaryColor, size: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    _FrostedCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: ProviderSearchWidget(
                        onTap: (doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final providerName =
                              data['name']?.toString() ?? 'Provider';
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => ProviderServicesPage(
                                providerId: doc.id,
                                providerName: providerName,
                              ),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration:
                              const Duration(milliseconds: 360),
                            ),
                          );
                        },
                      ),
                    ),

                    //Section Header
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.grid_view_rounded,
                            color: kPrimaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "home.available_services".tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kPrimaryColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app,
                                  size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text(
                                "Tap a service",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),

                    //Services List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(
                          bottom: 28,
                          top: 4,
                        ),
                        itemCount: serviceList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return ServiceTile(
                            service: serviceList[index],
                            index: index,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _GlassFab(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const ChatbotPage(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}

//Animated Background Helpers

double _lerp(double a, double b, double t) => a + (b - a) * t;

class _DiagonalGradientBackdrop extends StatelessWidget {
  const _DiagonalGradientBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5FFFE),
            Color(0xFFEFFFFE),
            Color(0xFFE6FAF7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double blurSigma;

  const _AnimatedBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    this.blurSigma = 30,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: _BlurredBlob(size: size, color: color, sigma: blurSigma),
    );
  }
}

class _BlurredBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double sigma;

  const _BlurredBlob({
    required this.size,
    required this.color,
    required this.sigma,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withOpacity(0.0),
              ],
              stops: const [0.2, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

//Frosted Card

class _FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _FrostedCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.7)),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

//Glass FAB

class _GlassFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _GlassFab({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: kPrimaryColor.withOpacity(0.85),
          elevation: 6,
          child: child,
        ),
      ),
    );
  }
}

//Category Theme

class _CategoryTheme {
  final List<Color> gradient;
  final Color iconBg;
  final Color iconFg;
  final List<BoxShadow> shadow;

  const _CategoryTheme({
    required this.gradient,
    required this.iconBg,
    required this.iconFg,
    required this.shadow,
  });
}

_CategoryTheme _themeFor(Service service) {
  final key = service.nameKey.split('.').last.toLowerCase();

  switch (key) {
    case 'cleaning':
      return _CategoryTheme(
        gradient: [const Color(0xFFA8E6CF), const Color(0xFFE8FFF6)],
        iconBg: const Color(0xFF76D7C4),
        iconFg: Colors.white,
        shadow: const [
          BoxShadow(color: Color(0x306BD6BF), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );
    case 'handyman':
      return _CategoryTheme(
        gradient: [const Color(0xFFFFD3B6), const Color(0xFFFFF1E7)],
        iconBg: const Color(0xFFFFB784),
        iconFg: Colors.white,
        shadow: const [
          BoxShadow(color: Color(0x30FFB784), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );
    case 'plumbing':
      return _CategoryTheme(
        gradient: [const Color(0xFFB3E5FC), const Color(0xFFEAF7FF)],
        iconBg: const Color(0xFF4FC3F7),
        iconFg: Colors.white,
        shadow: const [
          BoxShadow(color: Color(0x304FC3F7), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );
    case 'delivery':
      return _CategoryTheme(
        gradient: [const Color(0xFFFFF52D), const Color(0xFFF6FBD1)],
        iconBg: const Color(0xFFFFF52D),
        iconFg: Colors.white,
        shadow: const [
          BoxShadow(color: Color(0x30C0CA33), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );
    case 'assembly':
      return _CategoryTheme(
        gradient: [const Color(0xFFE1BEE7), const Color(0xFFF6EAFE)],
        iconBg: const Color(0xFFBA68C8),
        iconFg: Colors.white,
        shadow: const [
          BoxShadow(color: Color(0x30BA68C8), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );
    case 'moving':
      return _CategoryTheme(
        gradient: [const Color(0xFFFFAB91), const Color(0xFFFFE6DE)],
        iconBg: const Color(0xFFEF6C00),
        iconFg: Colors.white,
        shadow: const [
          BoxShadow(color: Color(0x30EF6C00), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );
    default: // more / others
      return _CategoryTheme(
        gradient: [const Color(0xFFB2EBF2), const Color(0xFFE7FBFD)],
        iconBg: kPrimaryColor,
        iconFg: Colors.white,
        shadow: const [
          BoxShadow(color: Color(0x3018AEAC), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );
  }
}

//SERVICE TILE

class ServiceTile extends StatefulWidget {
  final Service service;
  final int index;
  const ServiceTile({super.key, required this.service, required this.index});

  @override
  State<ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<ServiceTile> {
  bool _visible = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    // Staggered reveal based on index
    Future.delayed(Duration(milliseconds: 70 * (widget.index % 8)), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  void _navigate() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            ServiceProvidersPage(service: widget.service),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(widget.service);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) {
              setState(() => _pressed = false);
              _navigate();
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: theme.shadow,
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1,
                ),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: theme.iconBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(widget.service.icon,
                        color: theme.iconFg, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Text(
                      widget.service.nameKey.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  // trailing chevron
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade700, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

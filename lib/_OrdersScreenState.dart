import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_services.dart';
import '_OrderDetailsPage.dart';

const _brand = Color(0xFF18AEAC);

class OrdersScreen extends StatefulWidget {
  final VoidCallback onBackToServices;
  const OrdersScreen({super.key, required this.onBackToServices});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtl;
  late final Animation<double> _fadeIn;

  late final PageController _pageCtl;

  final FirebaseService firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _pageCtl = PageController(initialPage: 0);

    _fadeCtl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeInOut);
    _fadeCtl.forward();
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    _fadeCtl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingStream() {
    final userId = firebaseService.getCurrentUserId();
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  //UI helpers
  Widget _header() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(.92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _brand.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: _brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('my_orders'.tr(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _brand)),
                const SizedBox(height: 4),
                const Text(
                  'Track your bookings and history',
                  style: TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFB2DFDB),
                  ),
                  child: Icon(icon, size: 72, color: _brand),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _brand)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onBackToServices,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.explore, color: Colors.white),
              label: Text("start_exploring".tr(),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final b = doc.data();
    final service = (b['service'] ?? '').toString();
    final date = (b['date'] ?? '').toString();
    final time = (b['time'] ?? '').toString();
    final address = (b['address'] ?? '').toString();
    final status = (b['status'] ?? 'pending').toString().toLowerCase();

    final Color statusColor = switch (status) {
      'pending' => Colors.orange,
      'canceled' => Colors.red,
      'completed' => Colors.green,
      _ => Colors.grey,
    };

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                OrderDetailsPage(docId: doc.id, booking: b),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        key: ValueKey(doc.id),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(.92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(.07),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.black12.withOpacity(.04)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: _brand.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment, color: _brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.isEmpty ? '—' : service,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            fontSize: 11.5,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(time,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> items) {
    if (items.isEmpty) {
      return _empty('no_pending_orders'.tr(), 'no_pending_sub'.tr(),
          Icons.hourglass_empty);
    }
    return ListView.builder(
      key: const PageStorageKey('pendingList'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      itemCount: items.length,
      itemBuilder: (_, i) => _orderCard(items[i]),
    );
  }

  Widget _historyList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> items) {
    if (items.isEmpty) {
      return _empty('no_order_history'.tr(), 'no_history_sub'.tr(),
          Icons.assignment_turned_in);
    }
    return ListView.builder(
      key: const PageStorageKey('historyList'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      itemCount: items.length,
      itemBuilder: (_, i) => _orderCard(items[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        children: [
          _header(),

          _GlassSlideBar(
            labels: [tr('pending'), tr('history')],
            controller: _pageCtl,
            activeColor: _brand,
            backgroundColor: Colors.grey[200]!,
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _bookingStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                final pending =
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final history =
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                for (final d in allDocs) {
                  final s =
                  (d.data()['status'] ?? 'pending').toString().toLowerCase();
                  (s == 'pending' ? pending : history).add(d);
                }

                return PageView(
                  controller: _pageCtl,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _pendingList(pending),
                    _historyList(history),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSlideBar extends StatefulWidget {
  final List<String> labels; // must be length = 2
  final PageController controller;
  final Color activeColor;
  final Color backgroundColor;

  const _GlassSlideBar({
    required this.labels,
    required this.controller,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  State<_GlassSlideBar> createState() => _GlassSlideBarState();
}

class _GlassSlideBarState extends State<_GlassSlideBar>
    with SingleTickerProviderStateMixin {
  // Continuous position in [0..1]
  double _pos = 0.0;
  late final AnimationController _snapCtl;
  late Animation<double> _snapAnim;

  void _syncFromPage() {
    if (!widget.controller.hasClients) return;
    final p = widget.controller.page ?? widget.controller.initialPage.toDouble();
    setState(() => _pos = p.clamp(0.0, 1.0));
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromPage);

    _snapCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromPage);
    _snapCtl.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _snapCtl.stop();
    _snapAnim = Tween<double>(begin: _pos, end: target)
        .animate(CurvedAnimation(parent: _snapCtl, curve: Curves.easeOutCubic));
    _snapCtl
      ..reset()
      ..addListener(() => setState(() => _pos = _snapAnim.value))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          // keep in sync with pages
          final page = target.round();
          widget.controller.animateToPage(
            page,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      })
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.labels.length == 2);

    return LayoutBuilder(
      builder: (context, c) {
        const outerPad = 16.0;
        const innerPad = 4.0;
        final w = c.maxWidth;
        const h = 48.0;

        final trackW = w - (outerPad * 2);
        final segW = (trackW - innerPad * 2) / 2;

        final t = _pos.clamp(0.0, 1.0);
        final left = outerPad + innerPad + (segW * t) + (t * innerPad);

        return SizedBox(
          height: h,
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (d) {
              final dx = d.localPosition.dx;
              // left half -> 0, right half -> 1
              final target = dx < w / 2 ? 0.0 : 1.0;
              _animateTo(target);
            },
            onHorizontalDragUpdate: (d) {
              final delta = d.primaryDelta ?? 0.0;
              final usable = segW + innerPad;
              if (usable <= 0) return;
              setState(() {
                _pos = (_pos + (delta / usable)).clamp(0.0, 1.0);
              });
            },
            onHorizontalDragEnd: (_) {
              final target = (_pos < 0.5) ? 0.0 : 1.0;
              _animateTo(target);
            },
            child: Stack(
              children: [
                // Track
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: outerPad),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: left,
                  top: 4,
                  bottom: 4,
                  width: segW,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.activeColor.withOpacity(.95),
                              widget.activeColor.withOpacity(.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.activeColor.withOpacity(.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: outerPad),
                    child: Row(
                      children: List.generate(2, (i) {
                        final selected =
                            (t < 0.5 && i == 0) || (t >= 0.5 && i == 1);
                        final textColor =
                        selected ? Colors.white : Colors.black54;

                        return Expanded(
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                              child: Text(widget.labels[i]),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_services.dart';
import 'TabBarWidget.dart';
import '_OrderDetailsPage.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback onBackToServices;

  const OrdersScreen({super.key, required this.onBackToServices});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  final FirebaseService firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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

  Widget _buildEmptyOrders(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  height: 160,
                  width: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFB2DFDB),
                  ),
                  child: Icon(icon, size: 80, color: const Color(0xFF007EA7)),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF007EA7)),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onBackToServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007EA7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.explore, color: Colors.white),
            label: Text(
              "start_exploring".tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final booking = doc.data();
    final status = (booking['status'] ?? 'pending').toLowerCase();

    final Color statusColor = {
      'pending': Colors.orange,
      'canceled': Colors.red,
      'completed': Colors.green,
    }[status] ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => OrderDetailsPage(
              docId: doc.id,
              booking: booking,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: const Icon(Icons.assignment, color: Color(0xFF007EA7)),
          title: Text(booking['service']),
          subtitle: Text(
            "📅 ${booking['date']}  ⏰ ${booking['time']}\n📍 ${booking['address']}",
          ),
          isThreeLine: true,
          trailing: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return FadeTransition(
      opacity: _fadeIn,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              "my_orders".tr(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007EA7),
              ),
            ),
            const SizedBox(height: 10),
            const TabBarWidget(),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _bookingStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyOrders(
                      "no_pending_orders".tr(),
                      "no_pending_sub".tr(),
                      Icons.hourglass_empty,
                    );
                  }

                  final docs = snapshot.data!.docs;
                  final pending = docs
                      .where((doc) => (doc.data()['status'] ?? 'pending') == 'pending')
                      .toList();
                  final history = docs
                      .where((doc) => (doc.data()['status'] ?? 'pending') != 'pending')
                      .toList();

                  return TabBarView(
                    children: [
                      pending.isEmpty
                          ? _buildEmptyOrders(
                        "no_pending_orders".tr(),
                        "no_pending_sub".tr(),
                        Icons.hourglass_empty,
                      )
                          : ListView(children: pending.map(_buildBookingTile).toList()),
                      history.isEmpty
                          ? _buildEmptyOrders(
                        "no_order_history".tr(),
                        "no_history_sub".tr(),
                        Icons.assignment_turned_in_outlined,
                      )
                          : ListView(children: history.map(_buildBookingTile).toList()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

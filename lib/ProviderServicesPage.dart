import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '_BookingScreenState.dart';

class ProviderServicesPage extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderServicesPage({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends State<ProviderServicesPage> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> cart = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProviderServices();
  }

  Future<void> fetchProviderServices() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('providers')
          .where('name', isEqualTo: widget.providerName)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        services = List<Map<String, dynamic>>.from(data['services']);
      }
    } catch (e) {
      print("Error fetching services: $e");
    }

    setState(() {
      loading = false;
    });
  }

  void addToCart(Map<String, dynamic> service) {
    setState(() {
      cart.add(service);
    });
  }

  void removeFromCart(Map<String, dynamic> service) {
    setState(() {
      cart.remove(service);
    });
  }

  void goToBookingPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => BookingScreen(
          services: cart,
          providerName: widget.providerName,
          totalCost: cart.fold(0.0, (sum, item) => sum + (item['price'] ?? 0)),
        ),
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

  bool isInCart(Map<String, dynamic> service) {
    return cart.contains(service);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFFB2DFDB),
        iconTheme: const IconThemeData(color: Color(0xFF007EA7)),
        title: Text(
          widget.providerName,
          style: const TextStyle(
            color: Color(0xFF007EA7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
          ? const Center(child: Text("No services available."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final inCart = isInCart(service);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Container(
                          height: 120,
                          width: 120,
                          color: const Color(0xFFB2DFDB),
                          child: const Icon(Icons.miscellaneous_services,
                              size: 50, color: Color(0xFF007EA7)),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () {
                            inCart
                                ? removeFromCart(service)
                                : addToCart(service);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: inCart
                                  ? Colors.redAccent
                                  : const Color(0xFF007EA7),
                            ),
                            child: Icon(
                              inCart ? Icons.remove : Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                "${service['price'].toString()} SAR",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007EA7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: goToBookingPage,
        icon: const Icon(Icons.shopping_cart_checkout, color: Color(0xFF007EA7)),
        label: Text(
          "Book (${cart.length}) • ${cart.fold(0.0, (sum, item) => sum + (item['price'] ?? 0))} SAR",
          style: const TextStyle(color: Color(0xFF007EA7)),
        ),
        backgroundColor: const Color(0xFFB2DFDB),
      )
          : null,
    );
  }
}

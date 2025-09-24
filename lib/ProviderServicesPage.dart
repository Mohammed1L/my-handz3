import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '_BookingScreenState.dart';

const Color kPrimaryColor = Color(0xFF18AEAC);

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        title: Text(
          widget.providerName,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : services.isEmpty
          ? const Center(child: Text("No services available."))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final inCart = isInCart(service);

          return Material(
            color: Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                inCart ? removeFromCart(service) : addToCart(service);
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.miscellaneous_services,
                        color: kPrimaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                "${service['price'].toString()} SAR",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: 6,
                                width: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.schedule, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              const Text(
                                'Flexible timing',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        inCart ? removeFromCart(service) : addToCart(service);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: inCart ? Colors.redAccent : kPrimaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(inCart ? Icons.remove : Icons.add, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              inCart ? 'Remove' : 'Add',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: goToBookingPage,
        icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
        label: Text(
          "Book (${cart.length}) • ${cart.fold(0.0, (sum, item) => sum + (item['price'] ?? 0))} SAR",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryColor,
      )
          : null,
    );
  }
}

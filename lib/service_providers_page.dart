import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'ProviderServicesPage.dart'; // Make sure this is the correct path
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_model.dart';

class ServiceProvidersPage extends StatelessWidget {
  final Service service;

  const ServiceProvidersPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final String categoryKey = service.nameKey.split('.').last.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr("providers_title", namedArgs: {"service": service.nameKey.tr()}),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF007EA7),
          ),
        ),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: const Color(0xFF007EA7),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('providers')
            .where('category', isEqualTo: categoryKey)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No providers available."));
          }

          final providers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final providerName = provider['name'];
              final providerId = provider.id;
              final image = provider['image'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProviderServicesPage(
                        providerId: providerId,
                        providerName: providerName,
                      ),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (image.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            image,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.business,
                                color: Color(0xFF007EA7)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    providerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: const [
                                      Icon(Icons.star,
                                          color: Colors.amber, size: 16),
                                      SizedBox(width: 4),
                                      Text('4.5 (200)',
                                          style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Available in your area',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '25–35 mins',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

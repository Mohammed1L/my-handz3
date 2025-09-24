import 'package:flutter/material.dart';
import 'package:senior_project/service_model.dart';
import 'package:senior_project/service_providers_page.dart';
import 'package:easy_localization/easy_localization.dart';

// --------------------- SERVICES PAGE ---------------------
const Color kPrimaryColor = Color(0xFF18AEAC);

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        elevation: 0,
        title: Text(
          "home.available_services".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: localizedServiceList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final service = localizedServiceList[index];
          return Material(
            color: Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceProvidersPage(service: service),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(service.icon, color: kPrimaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service.nameKey.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  List<Service> get localizedServiceList => [
    Service(nameKey: "service.cleaning", icon: Icons.cleaning_services),
    Service(nameKey: "service.handyman", icon: Icons.handyman),
    Service(nameKey: "service.plumbing", icon: Icons.plumbing),
    Service(nameKey: "service.delivery", icon: Icons.local_shipping),
    Service(nameKey: "service.assembly", icon: Icons.chair_alt),
    Service(nameKey: "service.moving", icon: Icons.move_to_inbox),
    Service(nameKey: "service.more", icon: Icons.more_horiz),
  ];
}


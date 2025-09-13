import 'package:flutter/material.dart';
import 'package:senior_project/service_model.dart';
import 'package:senior_project/service_providers_page.dart';
import 'package:easy_localization/easy_localization.dart';

// --------------------- SERVICES PAGE ---------------------
class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text("home.available_services".tr()),
        backgroundColor: const Color(0xFF007EA7),
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: localizedServiceList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final service = localizedServiceList[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceProvidersPage(service: service),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(service.icon, size: 36, color: const Color(0xFF007EA7)),
                  const SizedBox(height: 8),
                  Text(
                    service.nameKey.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
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


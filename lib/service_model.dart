import 'package:flutter/material.dart';

class Service {
  final String nameKey;
  final IconData icon;

  Service({required this.nameKey, required this.icon});
}

final List<Service> serviceList = [
  Service(nameKey: "service.cleaning", icon: Icons.cleaning_services),
  Service(nameKey: "service.handyman", icon: Icons.handyman),
  Service(nameKey: "service.plumbing", icon: Icons.plumbing),
  Service(nameKey: "service.delivery", icon: Icons.local_shipping),
  Service(nameKey: "service.assembly", icon: Icons.chair_alt),
  Service(nameKey: "service.moving", icon: Icons.move_to_inbox),
  Service(nameKey: "service.more", icon: Icons.more_horiz),
];

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';


class TabBarWidget extends StatelessWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(
          color: Color(0xFF007EA7),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        tabs: [
          Tab(text: "pending".tr()),
          Tab(text: "history".tr()),
        ],
      ),
    );
  }
}
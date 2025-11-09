import 'package:flutter/material.dart';

class CompanyDashboardPage extends StatelessWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Welcome! Your registration was sent. This is a placeholder dashboard.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}



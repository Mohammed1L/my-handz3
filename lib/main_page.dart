import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import '_NotificationsScreenState.dart';
import '_OrdersScreenState.dart';
import 'HomeScreenState.dart';
import '_PromotionScreenState.dart';

// --------------------- MAIN PAGE ---------------------
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late List<Widget> _pages;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _fadeController.reset();
      _fadeController.forward();
    });
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _pages = [
      const HomeScreen(),
      OrdersScreen(
        onBackToServices: () {
          _onItemTapped(0);
        },
      ),
      PromotionScreen(
        onBackToServices: () {
          _onItemTapped(0);
        },
      ),
      NotificationsScreen(
        onBackToHome: () {
          _onItemTapped(0);
        },
      ),
    ];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Scaffold(
      endDrawer: const CustomDrawer(),
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Color(0xFF007EA7)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB2DFDB), Color(0xFFB2DFDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Image.asset(
          'assets/images/Screenshot_2025-03-24_213038-removebg-preview.png',
          height: 50,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF007EA7),
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home), label: "homeMain".tr()),
            BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_bag), label: "orders".tr()),
            BottomNavigationBarItem(
                icon: const Icon(Icons.card_giftcard),
                label: "promotions".tr()),
            BottomNavigationBarItem(
                icon: const Icon(Icons.notifications),
                label: "notifications".tr()),
          ],
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '_ProfilePageState.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with SingleTickerProviderStateMixin {
  String? _userName;
  final GlobalKey _drawerKey = GlobalKey();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("logout".tr()),
        content: Text("log_out_confirm".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF007EA7)),
            child: Text("cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text("logout".tr(),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userName');
      await prefs.remove('profileImage');
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("log_out_success".tr()),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '';
    });
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String text,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Material(
        color: Colors.transparent,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () => Navigator.of(context).pop(),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF007EA7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: _drawerKey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // ---------- Drawer Header ----------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB2DFDB), Color(0xFF007EA7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.only(topRight: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 30, color: Color(0xFF007EA7)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _userName != null && _userName!.isNotEmpty
                            ? _userName!
                            : "",
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ---------- Drawer Items ----------
              _buildDrawerItem(
                context,
                Icons.person_outline,
                "my_profile".tr(),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const MyProfilePage(),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
              ),
              _buildDrawerItem(context, Icons.mail_outline, "contact_us".tr()),
              const SizedBox(height: 8),
              _buildDrawerItem(
                  context, Icons.engineering, "become_worker".tr()),
              const SizedBox(height: 8),
              _buildDrawerItem(
                  context, Icons.apartment, "register_company".tr()),
              const SizedBox(height: 8),
              const Divider(thickness: 1, indent: 16, endIndent: 16),
              const SizedBox(height: 8),
              _buildDrawerItem(context, Icons.share_outlined, "share".tr()),
              const SizedBox(height: 8),
              _buildDrawerItem(context, Icons.star_border, "rate".tr()),
              const SizedBox(height: 8),
              _buildDrawerItem(
                context,
                Icons.logout,
                "logout".tr(),
                onTap: () => _confirmLogout(context),
              ),

              const Spacer(),

              // ---------- Footer ----------
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.language, color: Color(0xFF007EA7)),
                    onPressed: () async {
                      final newLocale = context.locale.languageCode == 'en'
                          ? const Locale('ar')
                          : const Locale('en');

                      OverlayEntry? overlayEntry;
                      overlayEntry = OverlayEntry(
                        builder: (_) => AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          child: Container(
                            color: Colors.white,
                          ),
                        ),
                      );

                      Overlay.of(context).insert(overlayEntry);

                      await Future.delayed(const Duration(milliseconds: 250));

                      await context.setLocale(newLocale);

                      await Future.delayed(const Duration(milliseconds: 200));

                      if (context.mounted) Navigator.of(context).pop();

                      overlayEntry.remove();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newLocale.languageCode == 'ar'
                                ? "تم تغيير اللغة إلى العربية"
                                : "Language changed to English",
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
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
  String? _phone;
  File? _profileImage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    final imagePath = prefs.getString('profileImage');
    File? img;
    if (imagePath != null) {
      final f = File(imagePath);
      if (f.existsSync()) img = f;
    }

    setState(() {
      _userName = (prefs.getString('userName') ?? '').trim();
      _phone = user?.phoneNumber ?? '';
      _profileImage = img;
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("logout".tr()),
        content: Text("log_out_confirm".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF007EA7),
            ),
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

  // Drawer item with soft “glass card” look
  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18AEAC).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF18AEAC)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Gradient header with decorative circles
  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF18AEAC), Color(0xFF0D8A88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(25),
        ),
      ),
      child: Stack(
        children: [
          // Soft decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -16,
            bottom: -16,
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? const Icon(Icons.person, color: Colors.white, size: 30)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_userName?.isNotEmpty ?? false) ? _userName! : "my_profile".tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _phone?.isNotEmpty == true ? _phone! : '—',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Two-button segmented language switch (no swapping)
  Widget _languageSegment() {
    final isArabic = context.locale.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: _segBtn(
                label: 'English',
                selected: !isArabic,
                onTap: () async {
                  if (!mounted) return;
                  if (!isArabic) return; // already English
                  await context.setLocale(const Locale('en'));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language changed to English'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _segBtn(
                label: 'العربية',
                selected: isArabic,
                onTap: () async {
                  if (!mounted) return;
                  if (isArabic) return; // already Arabic
                  await context.setLocale(const Locale('ar'));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تغيير اللغة إلى العربية'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segBtn({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF18AEAC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black.withOpacity(0.55),
          fontSize: 12.5,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<String> _appVersion() async {
    try {
      // If you have package_info_plus, you can use it here:
      // final info = await PackageInfo.fromPlatform();
      // return 'v${info.version} (${info.buildNumber})';
      return 'v1.0.0'; // fallback text to avoid new deps
    } catch (_) {
      return 'v1.0.0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 10),

              // Profile quick access
              _drawerItem(
                icon: Icons.person_outline,
                title: "my_profile".tr(),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const MyProfilePage(),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                      transitionDuration: const Duration(milliseconds: 350),
                    ),
                  );
                },
              ),

              _sectionTitle("general".tr()),

              _drawerItem(
                icon: Icons.mail_outline,
                title: "contact_us".tr(),
                onTap: () => Navigator.of(context).pop(),
              ),
              _drawerItem(
                icon: Icons.engineering,
                title: "become_worker".tr(),
                onTap: () => Navigator.of(context).pop(),
              ),
              _drawerItem(
                icon: Icons.apartment,
                title: "register_company".tr(),
                onTap: () => Navigator.of(context).pop(),
              ),
              _drawerItem(
                icon: Icons.share_outlined,
                title: "share".tr(),
                onTap: () => Navigator.of(context).pop(),
              ),
              _drawerItem(
                icon: Icons.star_border,
                title: "rate".tr(),
                onTap: () => Navigator.of(context).pop(),
              ),

              _sectionTitle("language".tr()),
              _languageSegment(),

              const Spacer(),

              // Logout
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    "logout".tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Footer (version)
              FutureBuilder<String>(
                future: _appVersion(),
                builder: (context, snapshot) {
                  final v = snapshot.data ?? '';
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Opacity(
                      opacity: 0.6,
                      child: Text(
                        "© ${DateTime.now().year}  •  $v",
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

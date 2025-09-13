import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage>
    with SingleTickerProviderStateMixin {
  String _userName = '';
  String _phoneNumber = '';
  File? _profileImage;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      _userName = prefs.getString('userName') ?? 'Unknown';
      _phoneNumber = user?.phoneNumber ?? '+966 5XXXXXXX';
      final imagePath = prefs.getString('profileImage');
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImage = File(imagePath);
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', picked.path);
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("logout".tr()),
        content: Text("log_out_confirm".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor:const Color(0xFF007EA7)),
            child: Text("cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text("logout".tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userName');
      await prefs.remove('profileImage');
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("log_out_success".tr()),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Widget _buildInfoCard(IconData icon, String labelKey, String value) {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: isRtl ? null : Icon(icon, color: const Color(0xFF007EA7)),
        trailing: isRtl ? Icon(icon, color: const Color(0xFF007EA7)) : null,
        title: Text(labelKey.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            )),
        subtitle: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    return Scaffold(
      appBar: AppBar(
        title: Text("my_profile".tr(),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF007EA7)),
            ),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: const Color(0xFF007EA7),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFB2DFDB),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/images/Screenshot_2025-03-24_213038-removebg-preview.png')
                    as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit, size: 16),
                label: Text("change_photo".tr()),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007EA7),
                ),
              ),
              const SizedBox(height: 30),

              _buildInfoCard(Icons.person, "name", _userName),
              _buildInfoCard(Icons.phone, "phone_number", _phoneNumber),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text("logout".tr(), style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

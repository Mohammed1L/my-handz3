import 'package:flutter/material.dart';
import 'main_page.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:senior_project/services/firebase_Services.dart';
import 'LocationPickerScreen.dart';

class BookingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final String providerName;
  final double totalCost;

  const BookingScreen({
    super.key,
    required this.services,
    required this.providerName,
    required this.totalCost,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FirebaseService firebaseService = FirebaseService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _timeController.text = picked.format(context);
    }
  }

  Future<void> _pickLocation() async {
    final LatLng? selected = await Navigator.push(
      context,
        PageRouteBuilder(pageBuilder: (_, __, ___) => const LocationPickerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (selected != null) {
      _addressController.text =
      'Lat: ${selected.latitude.toStringAsFixed(4)}, Lng: ${selected.longitude.toStringAsFixed(4)}';
    }
  }

  Future<void> _submitBooking() async {
    final date = _dateController.text.trim();
    final time = _timeController.text.trim();
    final address = _addressController.text.trim();

    if (date.isEmpty || time.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await firebaseService.createBookingRequest(
        service: widget.services.map((e) => e['name']).join(', '),
        date: date,
        time: time,
        address: address,
      );

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainPage(), // make sure HomeScreen is imported
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking successful!',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF007EA7)) : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildServiceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Selected Services",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.services.map((s) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s['name']),
            Text("${s['price']} SAR"),
          ],
        )),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("${widget.totalCost.toStringAsFixed(2)} SAR",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Book a Service',style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF007EA7),
        )),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: const Color(0xFF007EA7),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildServiceSummary(),
                const SizedBox(height: 24),
                _buildTextField(
                  label: "Date",
                  controller: _dateController,
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: "Time",
                  controller: _timeController,
                  icon: Icons.access_time,
                  readOnly: true,
                  onTap: _selectTime,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: "Address",
                  controller: _addressController,
                  icon: Icons.location_on,
                  readOnly: true,
                  onTap: _pickLocation,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitBooking,
                    icon: const Icon(Icons.check, color: Color(0xFF007EA7)),
                    label: const Text(
                      "Confirm Booking",
                      style: TextStyle(color: Color(0xFF007EA7)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB2DFDB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

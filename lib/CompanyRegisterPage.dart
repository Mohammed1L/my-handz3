import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const Color kPrimaryColor = Color(0xFF18AEAC);
const Color kAccentColor = Color(0xFF007EA7);

class CompanyRegisterPage extends StatefulWidget {
  const CompanyRegisterPage({super.key});

  @override
  State<CompanyRegisterPage> createState() => _CompanyRegisterPageState();
}

class _CompanyRegisterPageState extends State<CompanyRegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<TextEditingController> _serviceControllers = [
    TextEditingController(),
  ];

  bool _submitting = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    for (final c in _serviceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final base = _requiredValidator(value);
    if (base != null) return base;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    final base = _requiredValidator(value);
    if (base != null) return base;
    if (value!.trim() != _passwordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors.')),
      );
      return;
    }

    final services = _serviceControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final emailBody = _buildEmailBody(services);

    setState(() {
      _submitting = true;
    });

    // Show modal loading indicator while sending
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final isConfigured =
          dotenv.env['EMAILJS_SERVICE_ID']?.isNotEmpty == true &&
              dotenv.env['EMAILJS_TEMPLATE_ID']?.isNotEmpty == true &&
              dotenv.env['EMAILJS_PUBLIC_KEY']?.isNotEmpty == true;

      if (isConfigured) {
        await _sendViaEmailJS(emailBody);
      } else {
        await _sendViaMailto(emailBody);
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      setState(() {
        _submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your registration has been sent successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to dashboard placeholder
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacementNamed('/companyDashboard');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send registration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _buildEmailBody(List<String> services) {
    final buffer = StringBuffer()
      ..writeln('New Company Registration')
      ..writeln('-------------------------')
      ..writeln('Company name: ${_companyNameController.text.trim()}')
      ..writeln('Company email: ${_emailController.text.trim()}')
      ..writeln('Phone number: ${_phoneController.text.trim()}')
      ..writeln('Address: ${_addressController.text.trim()}')
      ..writeln('Description: ${_descriptionController.text.trim().isEmpty ? 'N/A' : _descriptionController.text.trim()}')
      ..writeln('Services: ${services.isEmpty ? 'N/A' : services.join(', ')}');
    return buffer.toString();
  }

  Future<void> _sendViaMailto(String body) async {
    final subject = Uri.encodeComponent('New Company Registration');
    final encodedBody = Uri.encodeComponent(body);
    final uri = Uri.parse('mailto:mahertorke@gmail.com?subject=$subject&body=$encodedBody');
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched) {
        throw Exception('Could not open email client.');
      }
    } else {
      throw Exception('Email client not available.');
    }
  }

  Future<void> _sendViaEmailJS(String body) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID']!;
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID']!;
    final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY']!;

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final payload = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'to_email': 'mahertorke@gmail.com',
        'subject': 'New Company Registration',
        'message': body,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('EmailJS error (${response.statusCode}): ${response.body}');
    }
  }

  void _addServiceField() {
    setState(() {
      _serviceControllers.add(TextEditingController());
    });
  }

  List<Widget> _buildServiceInputs() {
    final widgets = <Widget>[];
    for (int i = 0; i < _serviceControllers.length; i++) {
      widgets.add(Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _serviceControllers[i],
              decoration: InputDecoration(
                labelText: 'Service ${i + 1}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            onPressed: _serviceControllers.length > 1
                ? () => setState(() {
              final removed = _serviceControllers.removeAt(i);
              removed.dispose();
            })
                : null,
          ),
        ],
      ));
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F7),
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        title: const Text('Register as Company'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide = constraints.maxWidth >= 800;
          final double maxFormWidth = wide ? 760 : constraints.maxWidth - 32;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: Column(
                  children: [
                    // Decorative intro card (keeps previous design)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.apartment, color: kPrimaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tell us about your company so we can verify and enable bookings for your services.',
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: [
                                  _buildField(
                                    label: 'Company name',
                                    controller: _companyNameController,
                                    validator: _requiredValidator,
                                    width: wide ? (maxFormWidth - 14) / 2 : maxFormWidth,
                                  ),
                                  _buildField(
                                    label: 'Company email',
                                    controller: _emailController,
                                    validator: _emailValidator,
                                    keyboardType: TextInputType.emailAddress,
                                    width: wide ? (maxFormWidth - 14) / 2 : maxFormWidth,
                                  ),
                                  _buildField(
                                    label: 'Phone number',
                                    controller: _phoneController,
                                    validator: _requiredValidator,
                                    keyboardType: TextInputType.phone,
                                    width: wide ? (maxFormWidth - 14) / 2 : maxFormWidth,
                                  ),
                                  _buildField(
                                    label: 'Company address',
                                    controller: _addressController,
                                    validator: _requiredValidator,
                                    width: wide ? (maxFormWidth - 14) / 2 : maxFormWidth,
                                  ),
                                  _buildField(
                                    label: 'Password',
                                    controller: _passwordController,
                                    validator: _requiredValidator,
                                    obscureText: true,
                                    width: wide ? (maxFormWidth - 14) / 2 : maxFormWidth,
                                  ),
                                  _buildField(
                                    label: 'Confirm password',
                                    controller: _confirmPasswordController,
                                    validator: _confirmPasswordValidator,
                                    obscureText: true,
                                    width: wide ? (maxFormWidth - 14) / 2 : maxFormWidth,
                                  ),
                                  _buildField(
                                    label: 'Company description (optional)',
                                    controller: _descriptionController,
                                    validator: (_) => null,
                                    maxLines: 3,
                                    width: maxFormWidth,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              Text('Services offered', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
                              const SizedBox(height: 8),
                              ..._buildServiceInputs(),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _addServiceField,
                                  icon: const Icon(Icons.add, color: kPrimaryColor),
                                  label: const Text('Add service'),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Submit button (fixed height and visible text)
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _submitting ? null : _onSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: _submitting
                                        ? Row(
                                      key: const ValueKey('loading'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Sending...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                        : const Text(
                                      'Register',
                                      key: ValueKey('text'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

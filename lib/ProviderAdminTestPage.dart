import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderAdminTestPage extends StatefulWidget {
  const ProviderAdminTestPage({super.key});

  @override
  State<ProviderAdminTestPage> createState() => _ProviderAdminTestPageState();
}

class _ProviderAdminTestPageState extends State<ProviderAdminTestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<Map<String, TextEditingController>> serviceControllers = [];

  void addServiceField() {
    setState(() {
      serviceControllers.add({
        'name': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void removeServiceField(int index) {
    setState(() {
      serviceControllers.removeAt(index);
    });
  }

  Future<void> submitProvider() async {
    if (_formKey.currentState?.validate() != true) return;

    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final location = _locationController.text.trim();

    final services = serviceControllers.map((service) {
      return {
        'name': service['name']!.text.trim(),
        'price': double.tryParse(service['price']!.text.trim()) ?? 0,
      };
    }).toList();

    try {
      await FirebaseFirestore.instance.collection('providers').doc(id).set({
        'name': name,
        'category': category,
        'rating': 4.5,
        'location': location,
        'image': imageUrl,
        'services': services,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Provider added successfully!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState?.reset();
      setState(() {
        serviceControllers.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _locationController.dispose();
    for (var map in serviceControllers) {
      map['name']?.dispose();
      map['price']?.dispose();
    }
    super.dispose();
  }

  Widget _buildInput({required String label, required TextEditingController controller, bool requiredField = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007EA7), width: 1.5),
        ),
        floatingLabelStyle: const TextStyle(color: Color(0xFF007EA7)),
      ),
      validator: requiredField
          ? (val) => val == null || val.isEmpty ? "Required" : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Add Provider",
          style: TextStyle(color: Color(0xFF007EA7), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFB2DFDB),
        iconTheme: const IconThemeData(color: Color(0xFF007EA7)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Provider Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildInput(label: "Provider ID", controller: _idController),
              const SizedBox(height: 12),
              _buildInput(label: "Provider Name", controller: _nameController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                decoration: InputDecoration(
                  labelText: "Service Category",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF007EA7), width: 1.5),
                  ),
                  floatingLabelStyle: const TextStyle(color: Color(0xFF007EA7)),
                ),
                items: const [
                  DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
                  DropdownMenuItem(value: 'handyman', child: Text('Handyman')),
                  DropdownMenuItem(value: 'plumbing', child: Text('Plumbing')),
                  DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                  DropdownMenuItem(value: 'assembly', child: Text('Assembly')),
                  DropdownMenuItem(value: 'moving', child: Text('Moving')),
                  DropdownMenuItem(value: 'more', child: Text('More')),
                ],
                onChanged: (value) {
                  setState(() {
                    _categoryController.text = value!;
                  });
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildInput(label: "Image URL", controller: _imageUrlController, requiredField: false),
              const SizedBox(height: 12),
              _buildInput(label: "Location", controller: _locationController, requiredField: false),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text("Services", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),

              ...serviceControllers.asMap().entries.map((entry) {
                int index = entry.key;
                var controllers = entry.value;

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controllers['name'],
                            decoration: InputDecoration(
                              labelText: "Service Name",
                              floatingLabelStyle: const TextStyle(color: Color(0xFF007EA7)),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF007EA7), width: 1.5),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: controllers['price'],
                            decoration: InputDecoration(
                              labelText: "Price",
                              floatingLabelStyle: const TextStyle(color: Color(0xFF007EA7)),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF007EA7), width: 1.5),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => removeServiceField(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              TextButton.icon(
                onPressed: addServiceField,
                icon: const Icon(Icons.add, color: Color(0xFF007EA7)),
                label: const Text("Add Service", style: TextStyle(color: Color(0xFF007EA7))),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitProvider,
                  icon: const Icon(Icons.save, color: Color(0xFF007EA7)),
                  label: const Text("Submit Provider", style: const TextStyle(
                    color: Color(0xFF007EA7),
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2DFDB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

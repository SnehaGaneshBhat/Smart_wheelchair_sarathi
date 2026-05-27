//GUARDIAN_DETAILS_PAGE

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuardianDetailsPage extends StatefulWidget {
  const GuardianDetailsPage({super.key});

  @override
  State<GuardianDetailsPage> createState() => _GuardianDetailsPageState();
}

class _GuardianDetailsPageState extends State<GuardianDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guardian_name', _nameController.text.trim());
      await prefs.setString('guardian_age', _ageController.text.trim());
      await prefs.setString('patient_phone', _phoneController.text.trim());
      await prefs.setString('guardian_phone', _phoneController.text.trim());
      await prefs.setString('guardian_address', _addressController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guardian details saved")),
      );

      Navigator.pushReplacementNamed(context, '/guardian');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        title: const Text(
          "Enter Guardian Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.indigo.shade900,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24, bottom: 48),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.grey),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildTextField(_nameController, 'Full Name'),
                    const SizedBox(height: 16),
                    _buildTextField(_ageController, 'Age',
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, 'Patient Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.length < 10
                            ? 'Enter valid phone number'
                            : null),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, 'Guardian Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.length < 10
                            ? 'Enter valid phone number'
                            : null),
                    const SizedBox(height: 16),
                    _buildTextField(_addressController, 'Address', maxLines: 2),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade900,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Save and Continue",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ??
          (val) => val == null || val.isEmpty ? 'Enter $label' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

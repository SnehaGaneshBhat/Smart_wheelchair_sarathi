import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _patientPhoneController = TextEditingController();
  final TextEditingController _guardianPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _gender = 'Male';

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final name = _nameController.text.trim();
      final age = _ageController.text.trim();
      final patientPhone = _patientPhoneController.text.trim();
      final guardianPhone = _guardianPhoneController.text.trim();
      final address = _addressController.text.trim();
      final gender = _gender;

      // Save locally
      await prefs.setString('patient_name', name);
      await prefs.setString('patient_age', age);
      await prefs.setString('patient_phone', patientPhone);
      await prefs.setString('guardian_phone', guardianPhone);
      await prefs.setString('patient_address', address);
      await prefs.setString('patient_gender', gender);

      // Save to Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('patients').doc(uid).set({
          'uid': uid, // ✅ Store UID as a field
          'name': name,
          'age': age,
          'patientPhone': patientPhone,
          'guardianPhone': guardianPhone,
          'address': address,
          'gender': gender,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pushReplacementNamed(context, '/patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        title: const Text(
          "Enter Patient Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            Padding(
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
                    _buildTextField(
                      _patientPhoneController,
                      'Patient Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _guardianPhoneController,
                      'Guardian Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: _inputDecoration('Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _gender = value!),
                    ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? (val) => val == null || val.isEmpty ? 'Enter $label' : null,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  String? _phoneValidator(String? val) {
    if (val == null || val.isEmpty) return 'Enter phone number';
    if (val.length != 10) return 'Phone must be 10 digits';
    if (!RegExp(r'^[0-9]+$').hasMatch(val)) return 'Only numbers allowed';
    return null;
  }
}
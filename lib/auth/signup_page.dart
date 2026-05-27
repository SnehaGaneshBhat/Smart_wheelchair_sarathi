import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'patient';
  String _selectedGender = 'Male';

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Patient-specific
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _guardianPhoneController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final String email = "${_usernameController.text.trim()}@saarthi.app";
        final String password = _passwordController.text.trim();

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final uid = userCredential.user!.uid;

        Map<String, dynamic> userData = {
          'uid': uid,
          'username': _usernameController.text.trim(),
          'role': _selectedRole,
          'phone': _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (_selectedRole == 'patient') {
          userData.addAll({
            'name': _nameController.text.trim(),
            'age': _ageController.text.trim(),
            'gender': _selectedGender,
            'address': _addressController.text.trim(),
            'guardianPhone': _guardianPhoneController.text.trim(),
          });
        }

        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signed up as ${_usernameController.text}")),
        );

        Navigator.pushReplacementNamed(context, '/login');
      } on FirebaseAuthException catch (e) {
        String message = "Signup failed";
        if (e.code == 'email-already-in-use') {
          message = "Username already exists";
        } else if (e.code == 'weak-password') {
          message = "Password is too weak";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.length < 6) return "Password too short";
        return null;
      },
    );
  }

  Widget _buildPatientFields() {
    return Column(
      children: [
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
          validator: (value) => value == null || value.isEmpty ? "Enter name" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()),
          validator: (value) => value == null || value.isEmpty ? "Enter age" : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          items: ['Male', 'Female', 'Other']
              .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
              .toList(),
          onChanged: (value) => setState(() => _selectedGender = value!),
          decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: "Address", border: OutlineInputBorder()),
          validator: (value) => value == null || value.isEmpty ? "Enter address" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _guardianPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Guardian Phone Number", border: OutlineInputBorder()),
          validator: (value) {
            if (value == null || value.length != 10) return "Enter valid 10-digit phone";
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Signup", style: TextStyle(color: Colors.indigo.shade900)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.accessible_forward),
                Text("Saarthi", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: ['patient', 'guardian']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role[0].toUpperCase() + role.substring(1))))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                  decoration: const InputDecoration(labelText: "Select Role", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? "Enter username" : null,
                ),
                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: _passwordController,
                  label: "Password",
                  isVisible: _showPassword,
                  toggleVisibility: () => setState(() => _showPassword = !_showPassword),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return "Passwords do not match";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.length != 10) return "Enter valid 10-digit phone";
                    return null;
                  },
                ),

                if (_selectedRole == 'patient') _buildPatientFields(),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    backgroundColor: Colors.indigo.shade900,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up"),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text("Already have an account? Login"),
                ),
                              ],
            ),
          ),
        ),
      ),
    );
  }
}
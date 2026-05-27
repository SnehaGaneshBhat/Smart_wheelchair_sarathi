import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _userRole;

  // ✅ NEW: Store UID for navigation
  String? _uid;

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _userRole = null;
    });

    final String email = "${_usernameController.text.trim()}@saarthi.app";
    final String password = _passwordController.text.trim();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) {
        _showError("Login succeeded but user is null.");
        return;
      }

      final uid = user.uid;
      _uid = uid; // ✅ Store UID for later use

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        _showError("User profile not found in Firestore.");
        return;
      }

      final role = userDoc.data()?['role']?.toString().trim().toLowerCase();
      if (role == 'guardian' || role == 'patient') {
        setState(() => _userRole = role);
      } else {
        _showError("Unknown role: ${role ?? 'null'}");
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found for that username";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      }
      _showError(message);
    } catch (e) {
      _showError("Unexpected error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _continueToRoleScreen() {
    final role = _userRole?.toLowerCase();
    print("Continue pressed. Role: $role");

    if (_uid == null) {
      _showError("UID is missing. Cannot navigate.");
      return;
    }

    if (role == 'guardian') {
      Navigator.pushReplacementNamed(
        context,
        '/guardian_screen',
        arguments: _uid, // ✅ Pass UID
      );
    } else if (role == 'patient') {
      Navigator.pushReplacementNamed(
        context,
        '/patient_screen',
        arguments: _uid, // ✅ Pass UID
      );
    } else {
      _showError("Navigation failed. Unknown role: $role");
    }

    // 🔧 If named routes aren't working, try this fallback:
    // Navigator.pushReplacement(context, MaterialPageRoute(
    //   builder: (context) => GuardianScreen(uid: _uid!), // or PatientScreen
    // ));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.accessible_forward, size: 48),
              Text(
                "Saarthi",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter username" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter password" : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        backgroundColor: Colors.indigo.shade900,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text("Don't have an account? Sign Up"),
              ),
              const SizedBox(height: 30),

              if (_userRole != null) ...[
                Text(
                  "You are logged in as ${_userRole!.toUpperCase()}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _continueToRoleScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: const Text("Continue"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
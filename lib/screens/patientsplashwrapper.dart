import 'package:flutter/material.dart';
import 'patient_screen.dart'; // Make sure this import points to your actual file

class PatientSplashWrapper extends StatefulWidget {
   final String uid;

  const PatientSplashWrapper({required this.uid, super.key});
  //const PatientSplashWrapper({super.key});

  @override
  State<PatientSplashWrapper> createState() => _PatientSplashWrapperState();
}

class _PatientSplashWrapperState extends State<PatientSplashWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash
        ? Scaffold(
            backgroundColor: Colors.indigo.shade900,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.accessible_forward, size: 80, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    "Sarathi",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          )
        : PatientScreen(uid: widget.uid); // Show actual patient screen after splash
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GuardianViewPage extends StatefulWidget {
  const GuardianViewPage({super.key});

  @override
  State<GuardianViewPage> createState() => _GuardianViewPageState();
}

class _GuardianViewPageState extends State<GuardianViewPage> {
  String name = '', age = '', phone = '', address = '', gender = '';
  List<Map<String, String>> medicines = [];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('patient_name') ?? '';
      age = prefs.getString('patient_age') ?? '';
      phone = prefs.getString('patient_phone') ?? '';
      address = prefs.getString('patient_address') ?? '';
      gender = prefs.getString('patient_gender') ?? '';
      String? meds = prefs.getString('medicines');
      if (meds != null) {
        medicines = List<Map<String, String>>.from(json.decode(meds));
      }
    });
  }

  Widget _buildProfileTile(String label, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      leading: const Icon(Icons.info_outline),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian View'),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Patient Profile",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildProfileTile('Name', name),
          _buildProfileTile('Age', age),
          _buildProfileTile('Phone', phone),
          _buildProfileTile('Gender', gender),
          _buildProfileTile('Address', address),
          const SizedBox(height: 24),
          const Text("Medicine Reminders",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          for (var med in medicines)
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text(med['name'] ?? ''),
              subtitle: Text('Time: ${med['time'] ?? ''}'),
            ),
        ],
      ),
    );
  }
}

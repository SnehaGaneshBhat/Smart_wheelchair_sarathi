//PATIENT_SCREEN
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'chat.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientScreen extends StatefulWidget {
  final String uid;

  const PatientScreen({required this.uid, super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  BluetoothConnection? connection;
  BluetoothDevice? connectedDevice;
  bool _showSplash = true;

  String? guardianPhone;
  String? patientPhoneNumber;
  String? fromRoom;
  String? toRoom;

  final List<Map<String, dynamic>> rooms = [
    {'code': 'L', 'name': 'Living Room', 'icon': Icons.chair},
    {'code': 'B', 'name': 'Bedroom', 'icon': Icons.bed},
    {'code': 'K', 'name': 'Kitchen', 'icon': Icons.kitchen},
    {'code': 'S', 'name': 'Bathroom', 'icon': Icons.bathtub},
    {'code': 'T', 'name': 'Study', 'icon': Icons.menu_book},
  ];

  void selectRoom(String code) {
    setState(() {
      if (fromRoom == null) {
        fromRoom = code;
      } else if (toRoom == null && code != fromRoom) {
        toRoom = code;
        sendRoomCommand();
      }
    });
  }

  void sendRoomCommand() {
    if (fromRoom != null && toRoom != null && connection != null) {
      String command = fromRoom! + toRoom!;
      connection!.output.add(Uint8List.fromList("$command\n".codeUnits));
      print("Sent command: $command");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Navigating from $fromRoom to $toRoom")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          fromRoom = null;
          toRoom = null;
        });
      });
    }
  }

  void resetRoomSelection() {
    setState(() {
      fromRoom = null;
      toRoom = null;
    });
  }

  Color getButtonColor(String code) {
    if (fromRoom == code) return Colors.blue.shade200;
    if (toRoom == code) return Colors.green.shade200;
    return Colors.grey.shade300;
  }

  @override
  void initState() {
    super.initState();

    // Show splash for 2 seconds, then initiate Bluetooth dialog
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
      showBluetoothPopup();
    });

    loadpatientPhoneNumber(); // Load the phone number here
  }

  void loadpatientPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      patientPhoneNumber = prefs.getString('patientPhoneNumber') ??
          "+911234567890"; // fallback if not found
    });
  }

  void showBluetoothPopup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Connect to Wheelchair'),
        content: const Text('Scanning for devices named "ESP32-Car"...'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await connectToESP32();
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> connectToESP32() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status != PermissionStatus.granted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bluetooth permissions not granted.")),
      );
      return;
    }

    final bondedDevices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    final target = bondedDevices.firstWhere(
      (d) => d.name == "ESP32-Car",
      orElse: () => BluetoothDevice(name: '', address: ''),
    );

    if (target.name == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ESP32-Car not found in paired devices.")),
      );
      return;
    }

    try {
      BluetoothConnection newConnection =
          await BluetoothConnection.toAddress(target.address);
      setState(() {
        connection = newConnection;
        connectedDevice = target;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connected to ESP32-Car")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection failed: $e")),
      );
    }
  }

  void sendCommand(String cmd) {
    if (connection == null || !connection!.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not connected to wheelchair.")),
      );
      return;
    }

    try {
      connection!.output.add(Uint8List.fromList(cmd.codeUnits));
      connection!.output.allSent;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending command: $e")),
      );
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return Scaffold(
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
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              color: Color(0xff29367c),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Patient View",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.accessible_forward,
                            size: 28, color: Colors.white),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/patientProfile',
                            arguments: widget.uid, // ✅ Pass UID here
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.bluetooth_connected,
                              color: Colors.indigo),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              connection != null && connection!.isConnected
                                  ? "Connected to ESP32"
                                  : "Not connected",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Navigate to Room",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff29367c))),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            alignment: WrapAlignment.center,
                            runSpacing: 12,
                            children: rooms.map((room) {
                              return ElevatedButton.icon(
                                onPressed: () => selectRoom(room['code']),
                                icon: Icon(room['icon'], size: 20),
                                label: Text(room['name']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: getButtonColor(room['code']),
                                  foregroundColor: Colors.indigo.shade900,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: resetRoomSelection,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reset Selection"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red.shade800,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Manual Wheelchair Control",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff29367c))),
                          const SizedBox(height: 12),
                          WheelchairControls(onCommand: sendCommand),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Emergency Assistance 🚨",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              ChatScreen.addSystemMessage(
                                  "🚨 SOS Alert from Patient");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("SOS Alert Sent")),
                              );
                            },
                            icon: const Icon(Icons.warning_amber_rounded),
                            label: const Text("Send SOS Alert"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (guardianPhone != null &&
                                  guardianPhone!.isNotEmpty) {
                                _makeEmergencyCall(guardianPhone!);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Guardian phone number not set.")),
                                );
                              }
                            },
                            icon: const Icon(Icons.call),
                            label: const Text("Emergency Call"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(user: "Patient"),
            ),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.chat),
      ),
    );
  }
}

void _makeEmergencyCall(String phoneNumber) async {
  final Uri url = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}

class RoomButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const RoomButton({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo.shade50,
        foregroundColor: Colors.indigo.shade900,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class WheelchairControls extends StatelessWidget {
  final Function(String) onCommand;

  const WheelchairControls({super.key, required this.onCommand});

  Widget _controlButton(IconData icon, String label, String command) {
    return GestureDetector(
      onTap: () => onCommand(command),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.indigo.shade100,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 32, color: Colors.indigo.shade800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _controlButton(Icons.keyboard_arrow_up, "Forward", "F"),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(Icons.keyboard_arrow_left, "Left", "E"),
              const SizedBox(width: 20),
              _controlButton(Icons.radio_button_checked, "Stop", "P"),
              const SizedBox(width: 20),
              _controlButton(Icons.keyboard_arrow_right, "Right", "R"),
            ],
          ),
          const SizedBox(height: 10),
          _controlButton(Icons.keyboard_arrow_down, "Backward", "D"),
        ],
      ),
    );
  }
}
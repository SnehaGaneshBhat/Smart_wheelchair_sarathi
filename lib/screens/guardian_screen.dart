//GUARDIAN_SCREEN

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'chat.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuardianScreen extends StatefulWidget {
  final String uid;
  const GuardianScreen({required this.uid, super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;

  String? guardianPhoneNumber;
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
    connectToESP32();
    loadguardianPhoneNumber();
  }

  Future<void> loadguardianPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      guardianPhoneNumber = prefs.getString('guardian_phone');
    });
  }

  Future<void> connectToESP32() async {
    try {
      List<BluetoothDevice> bondedDevices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      BluetoothDevice? device = bondedDevices.firstWhere(
        (d) => d.name == "ESP32-Car",
        orElse: () => throw Exception("ESP32-Car not found"),
      );

      BluetoothConnection newConnection =
          await BluetoothConnection.toAddress(device.address);
      setState(() {
        connection = newConnection;
        isConnecting = false;
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

  void sendBluetoothCommand(String command) {
    if (isConnected) {
      connection!.output.add(Uint8List.fromList(command.codeUnits));
      connection!.output.allSent;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not connected to wheelchair.")),
      );
    }
  }

  void _makeEmergencyCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number not available.")),
      );
      return;
    }

    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    connection = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.accessible_forward,
                      size: 64, color: Colors.indigo),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
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
                decoration: BoxDecoration(
                  color: Colors.indigo.shade900,
                  borderRadius: const BorderRadius.only(
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
                          const Text("Guardian View",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const Icon(Icons.accessible_forward,
                              size: 28, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bluetooth connection status
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.bluetooth_connected,
                                  color: Colors.indigo.shade900),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isConnecting
                                      ? "Connecting to ESP32..."
                                      : "Connected to ESP32",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Room Navigation
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Navigate to Room",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900)),
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
                                      backgroundColor:
                                          getButtonColor(room['code']),
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

                      // Emergency call
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text("Contact the Patient",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red)),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _makeEmergencyCall(patientPhoneNumber),
                                icon: const Icon(Icons.call),
                                label: const Text("Call Patient"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade900,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 2,
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
                  builder: (_) => ChatScreen(user: "Guardian"),
                ),
              );
            },
            backgroundColor: Colors.indigo.shade900,
            child: const Icon(Icons.chat),
          ),
        );
      },
    );
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
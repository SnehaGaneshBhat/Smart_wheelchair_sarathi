import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  BluetoothConnection? _connection;
  List<String> _notifications = [];
  String _buffer = '';

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    try {
      final bondedDevices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      final esp32 = bondedDevices.firstWhere(
        (device) => device.name == "ESP32-Car",
        orElse: () => throw Exception("ESP32-Car not found."),
      );

      _connection = await BluetoothConnection.toAddress(esp32.address);
      _listenToIncomingData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connected to ESP32-Car")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bluetooth connection failed: $e")),
      );
    }
  }

  void _listenToIncomingData() {
    _connection?.input?.listen((Uint8List data) {
      final decoded = utf8.decode(data);
      _buffer += decoded;

      // Check for complete messages ending with '\n'
      while (_buffer.contains('\n')) {
        final index = _buffer.indexOf('\n');
        final message = _buffer.substring(0, index).trim();
        _buffer = _buffer.substring(index + 1);

        if (message.isNotEmpty) {
          setState(() {
            _notifications.insert(0, message); // Latest notification on top
          });
        }
      }
    }).onDone(() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bluetooth disconnected")),
      );
    });
  }

  @override
  void dispose() {
    _connection?.dispose();
    _connection = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: _notifications.isEmpty
          ? const Center(child: Text("No notifications yet."))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(_notifications[index]),
              ),
            ),
    );
  }
}

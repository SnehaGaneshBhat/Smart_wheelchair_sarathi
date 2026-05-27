import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class PatientProfilePage extends StatefulWidget {
  final String uid;

  const PatientProfilePage({required this.uid, super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  String name = '', age = '', phone = '', address = '', gender = '';
  List<Map<String, dynamic>> medicines = [];
  List<Map<String, dynamic>> filteredMedicines = [];
  bool _isLoading = true;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _fetchPatientData();
    _initNotifications();
  }

  Future<void> _fetchPatientData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;

        final medsQuery = await FirebaseFirestore.instance
            .collection('medicines')
            .where('uid', isEqualTo: widget.uid)
            .get();

        final parsedMeds = medsQuery.docs.map((doc) {
          final med = doc.data();
          return {
            'medicine_name': med['medicine_name'] ?? '',
            'time': med['time'] ?? '',
          };
        }).toList();

        parsedMeds.sort((a, b) {
          final t1 = a['time']!.split(':').map(int.parse).toList();
          final t2 = b['time']!.split(':').map(int.parse).toList();
          return t1[0] * 60 + t1[1] - (t2[0] * 60 + t2[1]);
        });

        if (mounted) {
          setState(() {
            name = data['name'] ?? '';
            age = data['age'] ?? '';
            phone = data['phone'] ?? '';
            gender = data['gender'] ?? '';
            address = data['address'] ?? '';
            medicines = parsedMeds;
            filteredMedicines = List.from(parsedMeds);
            _isLoading = false;
          });
        }

        for (var med in parsedMeds) {
          final timeParts = (med['time'] ?? '0:0').split(':');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          await _scheduleNotification(med['medicine_name'] ?? '', TimeOfDay(hour: hour, minute: minute));
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching patient data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidInitSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _scheduleNotification(String medicineName, TimeOfDay time) async {
    final androidDetails = AndroidNotificationDetails(
      'med_channel',
      'Medicine Reminders',
      channelDescription: 'Reminder to take medicine',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notifDetails = NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Medicine Reminder',
      'It\'s time to take $medicineName',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notifDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _addMedicine() async {
    TextEditingController medController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: medController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) selectedTime = picked;
              },
              child: const Text("Pick Reminder Time"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (medController.text.isNotEmpty) {
                final medicine = {
                  'uid': widget.uid,
                  'medicine_name': medController.text,
                  'time': '${selectedTime.hour}:${selectedTime.minute}',
                };

                await FirebaseFirestore.instance
                    .collection('medicines')
                    .add(medicine);

                await _scheduleNotification(medicine['medicine_name']!, selectedTime);

                setState(() {
                  medicines.add({
                    'medicine_name': medicine['medicine_name']!,
                    'time': medicine['time']!,
                  });
                  filteredMedicines = List.from(medicines);
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedicine(int index) async {
    final medToDelete = filteredMedicines[index];

    final query = await FirebaseFirestore.instance
        .collection('medicines')
        .where('uid', isEqualTo: widget.uid)
        .where('medicine_name', isEqualTo: medToDelete['medicine_name'])
        .where('time', isEqualTo: medToDelete['time'])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }

    setState(() {
      medicines.removeWhere((med) =>
          med['medicine_name'] == medToDelete['medicine_name'] &&
          med['time'] == medToDelete['time']);
      filteredMedicines = List.from(medicines);
    });
  }

  Future<void> _editMedicine(int index) async {
    final med = filteredMedicines[index];
    TextEditingController medController = TextEditingController(text: med['medicine_name']);
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse(med['time']!.split(':')[0]),
      minute: int.parse(med['time']!.split(':')[1]),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: medController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) selectedTime = picked;
              },
              child: const Text("Pick New Time"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final query = await FirebaseFirestore.instance
                  .collection('medicines')
                  .where('uid', isEqualTo: widget.uid)
                  .where('medicine_name', isEqualTo: med['medicine_name'])
                  .where('time', isEqualTo: med['time'])
                  .limit(1)
                  .get();

              if (query.docs.isNotEmpty) {
                await query.docs.first.reference.update({
                  'medicine_name': medController.text,
                  'time': '${selectedTime.hour}:${selectedTime.minute}',
                });

                medicines[index] = {
                  'medicine_name': medController.text,
                  'time': '${selectedTime.hour}:${selectedTime.minute}',
                };

                await _scheduleNotification(medController.text, selectedTime);
                setState(() => filteredMedicines = List.from(medicines));
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMedicine,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $name', style: const TextStyle(fontSize: 18)),
                  Text('Age: $age', style: const TextStyle(fontSize: 18)),
                  Text('Gender: $gender', style: const TextStyle(fontSize: 18)),
                  Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
                  Text('Address: $address', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Medicine',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      setState(() {
                        filteredMedicines = medicines
                            .where((med) => med['medicine_name']!
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Reminders:', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredMedicines.length,
                      itemBuilder: (context, index) {
                        final med = filteredMedicines[index];
                        return Card(
                          child: ListTile(
                            title: Text(med['medicine_name'] ?? ''),
                            subtitle: Text('Time: ${med['time']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editMedicine(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteMedicine(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

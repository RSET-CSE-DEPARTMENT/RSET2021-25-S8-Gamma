/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'UserData.dart';
class SlotSelectionPage extends StatefulWidget {
  const SlotSelectionPage({super.key});

  @override
  _SlotSelectionPageState createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  DateTime? selectedDate;
  bool isLoading = false;

  List<String> availableTimes = [
    "09:00 - 09:30",
    "09:30 - 10:00",
    "10:00 - 10:30",
    "10:30 - 11:00",
    "11:00 - 11:30",
    "11:30 - 12:00",
    "12:00 - 12:30",
    "12:30 - 01:00",
    "01:00 - 01:30",
    "01:30 - 02:00",
    "02:00 - 02:30",
    "02:30 - 03:00"
  ];

  // Track which slots are selected
  Map<String, bool> selectedSlots = {};

  @override
  void initState() {
    super.initState();
    // Initialize all slots as unselected
    for (var time in availableTimes) {
      selectedSlots[time] = false;
    }
  }

  Future<void> saveTempSlots() async {
    if (selectedDate == null ||
        selectedSlots.values.every((selected) => !selected)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a date and at least one time slot.")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    final selectedDateStr = selectedDate!.toIso8601String().split('T')[0];
    List<Map<String, String>> selectedTimeSlots =
        selectedSlots.entries.where((entry) => entry.value).map((entry) {
      final times = entry.key.split(' - ');
      return {
        'start_time': times[0],
        'end_time': times[1],
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/save_temp_slot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'case_id': 1,
          'prosecutor_id': UserData.userId,
          'date': selectedDateStr,
          'slots': selectedTimeSlots,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Slots saved successfully!")));
      } else {
        // Log server response body for more information
        print("Server response: ${response.body}");
        throw Exception("Failed to save slots");
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error saving slots: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prosecutor: Select Available Slots')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(selectedDate == null
                          ? "Select Date"
                          : "Selected Date: ${selectedDate!.toLocal().toIso8601String().split('T')[0]}"),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text("Choose Date"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: availableTimes.map((time) {
                      return CheckboxListTile(
                        title: Text(time),
                        value: selectedSlots[time],
                        onChanged: (bool? selected) {
                          setState(() {
                            selectedSlots[time] = selected ?? false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: saveTempSlots,
                    child: const Text("Save Selected Slots"),
                  ),
                ),
              ],
            ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'UserData.dart'; // Import UserData provider

class SlotSelectionPage extends StatefulWidget {
  const SlotSelectionPage({super.key});

  @override
  _SlotSelectionPageState createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  DateTime? selectedDate;
  bool isLoading = false;

  List<String> availableTimes = [
    "09:00 - 09:30",
    "09:30 - 10:00",
    "10:00 - 10:30",
    "10:30 - 11:00",
    "11:00 - 11:30",
    "11:30 - 12:00",
    "12:00 - 12:30",
    "12:30 - 01:00",
    "01:00 - 01:30",
    "01:30 - 02:00",
    "02:00 - 02:30",
    "02:30 - 03:00"
  ];

  Map<String, bool> selectedSlots = {};

  @override
  void initState() {
    super.initState();
    for (var time in availableTimes) {
      selectedSlots[time] = false;
    }
  }

  Future<void> saveTempSlots() async {
    final userData = Provider.of<UserData>(context, listen: false);

    if (selectedDate == null ||
        selectedSlots.values.every((selected) => !selected)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a date and at least one time slot.")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    final selectedDateStr = selectedDate!.toIso8601String().split('T')[0];
    List<Map<String, String>> selectedTimeSlots =
        selectedSlots.entries.where((entry) => entry.value).map((entry) {
      final times = entry.key.split(' - ');
      return {
        'start_time': times[0],
        'end_time': times[1],
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/save_temp_slot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'case_id': userData.caseId,
          'prosecutor_id': userData.userId, // Use the user_id from UserData
          'date': selectedDateStr,
          'slots': selectedTimeSlots,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Slots saved successfully!")));
      } else {
        print("Server response: ${response.body}");
        throw Exception("Failed to save slots");
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error saving slots: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Prosecutor: Select Available Slots')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(selectedDate == null
                          ? "Select Date"
                          : "Selected Date: ${selectedDate!.toLocal().toIso8601String().split('T')[0]}"),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text("Choose Date"),
                      ),
                    ],
                  ),
                ),
                Text("Prosecutor ID: ${userData.userId}"), // Display the userId
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: availableTimes.map((time) {
                      return CheckboxListTile(
                        title: Text(time),
                        value: selectedSlots[time],
                        onChanged: (bool? selected) {
                          setState(() {
                            selectedSlots[time] = selected ?? false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: saveTempSlots,
                    child: const Text("Save Selected Slots"),
                  ),
                ),
              ],
            ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class SlotConfirmationPage extends StatefulWidget {
  final int caseId;

  const SlotConfirmationPage({super.key, required this.caseId});

  @override
  _SlotConfirmationPageState createState() => _SlotConfirmationPageState();
}

class _SlotConfirmationPageState extends State<SlotConfirmationPage> {
  List<Map<String, dynamic>> tempSlots = [];
  Map<String, dynamic>? selectedSlot;
  bool isLoading = true;
  String errorMessage = '';
  String? fileLink; // Store the file link here
  TextEditingController emailController =
      TextEditingController(); // Controller for email input

  // Fetch temporary slots for the provided case ID
  Future<void> fetchTempSlots() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5000/api/temp_slots?case_id=${widget.caseId}'),
      );

      print("fetchTempSlots response status: ${response.statusCode}");
      print("fetchTempSlots response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          tempSlots = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load temp slots");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching slots: $e";
        isLoading = false;
        print("Error fetching slots: $e");
      });
    }
  }

  // Fetch the file link for the provided case ID
  Future<void> fetchFileLink() async {
    try {
      print("Fetching file link for case ID: ${widget.caseId}");

      // Fetch file ID using case ID
      final fileIdResponse = await http.post(
        Uri.parse('http://127.0.0.1:5000/get_file_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'case_id': widget.caseId}),
      );

      if (fileIdResponse.statusCode == 200) {
        final fileIdData = jsonDecode(fileIdResponse.body);
        final fileId = fileIdData['file_id'];
        print("Fetched file ID: $fileId");

        // Create the Google Drive URL
        final googleDriveUrl = 'https://drive.google.com/file/d/$fileId/view';
        setState(() {
          fileLink = googleDriveUrl;
        });
        print("Google Drive URL: $fileLink");
      } else {
        throw Exception("Failed to fetch file ID");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching file link: $e";
        print("Error fetching file link: $e");
      });
    }
  }

  Future<void> confirmSlot() async {
    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a time slot to confirm.")),
      );
      return;
    }

    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the prosecutor's email.")),
      );
      return;
    }

    try {
      print("Confirming slot for case ID: ${widget.caseId}");

      // Print the values being sent to the backend
      print("Selected Slot: ${selectedSlot}");
      print("Prosecutor's Email: ${emailController.text}");

      final response = await http.post(
        Uri.parse(
            'http://127.0.0.1:5000/sendemail1'), // Backend endpoint for email sending
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'case_id': widget.caseId,
          'date': selectedSlot!['date'],
          'start_time': selectedSlot!['start_time'],
          'end_time': selectedSlot!['end_time'],
          'email':
              emailController.text, // Send email with the confirmation details
        }),
      );

      print("confirmSlot response status: ${response.statusCode}");
      print("confirmSlot response body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Slot confirmed and email sent!")),
        );
        setState(() {
          selectedSlot = null;
        });
      } else {
        throw Exception("Failed to confirm slot");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error confirming slot: $e")),
      );
      print("Error confirming slot: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTempSlots();
    fetchFileLink(); // Fetch file link when the page initializes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Defense: Confirm Slot')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  // Wrap with SingleChildScrollView to prevent overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fileLink != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: InkWell(
                            onTap: () async {
                              final Uri url = Uri.parse(fileLink!);
                              print("Opening URL: $url");
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                print('Could not launch $url');
                              }
                            },
                            child: const Text(
                              "View Case File",
                              style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButton<Map<String, dynamic>>(
                          hint: const Text("Select Time Slot"),
                          value: selectedSlot,
                          onChanged: (value) {
                            setState(() {
                              selectedSlot = value;
                              print("Selected slot: $selectedSlot");
                            });
                          },
                          items: tempSlots.map((slot) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: slot,
                              child: Text(
                                  "${slot['date']} ${slot['start_time']} - ${slot['end_time']}"),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Enter Prosecutor's Email",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: confirmSlot,
                          child: const Text("Confirm Slot"),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red, // Ensure button is properly styled
                          ),
                          child: const Text("Cancel Slot Selection"),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class SlotConfirmationPage extends StatefulWidget {
  final int caseId;

  const SlotConfirmationPage({super.key, required this.caseId});

  @override
  _SlotConfirmationPageState createState() => _SlotConfirmationPageState();
}

class _SlotConfirmationPageState extends State<SlotConfirmationPage> {
  List<Map<String, dynamic>> tempSlots = [];
  Map<String, dynamic>? selectedSlot;
  bool isLoading = true;
  String errorMessage = '';
  String? fileLink; // Store the file link here
  String? caseTextToShow; // Store the case text here
  TextEditingController emailController = TextEditingController();

  // Fetch temporary slots for the provided case ID
  Future<void> fetchTempSlots() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5000/api/temp_slots?case_id=${widget.caseId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          tempSlots = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load temp slots");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching slots: $e";
        isLoading = false;
      });
    }
  }

  // Fetch the file link for the provided case ID
  Future<void> fetchFileLink() async {
    try {
      final fileIdResponse = await http.post(
        Uri.parse('http://127.0.0.1:5000/get_file_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'case_id': widget.caseId}),
      );

      if (fileIdResponse.statusCode == 200) {
        final fileIdData = jsonDecode(fileIdResponse.body);
        final fileId = fileIdData['file_id'];
        final googleDriveUrl = 'https://drive.google.com/file/d/$fileId/view';
        setState(() {
          fileLink = googleDriveUrl;
        });
      } else {
        throw Exception("Failed to fetch file ID");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching file link: $e";
      });
    }
  }

  // Fetch case text for the provided case ID
  Future<void> fetchCaseText() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/get_case_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'case_id': widget.caseId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          caseTextToShow = data['case_text'];
        });
      } else {
        throw Exception("Failed to fetch case text");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching case text: $e";
      });
    }
  }

  Future<void> confirmSlot() async {
    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a time slot to confirm.")),
      );
      return;
    }

    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the prosecutor's email.")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/sendemail1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'case_id': widget.caseId,
          'date': selectedSlot!['date'],
          'start_time': selectedSlot!['start_time'],
          'end_time': selectedSlot!['end_time'],
          'email': emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Slot confirmed and email sent!")),
        );
        setState(() {
          selectedSlot = null;
        });
      } else {
        throw Exception("Failed to confirm slot");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error confirming slot: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTempSlots();
    fetchFileLink();
    fetchCaseText(); // Fetch case text when the page initializes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Defense: Confirm Slot')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fileLink != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: InkWell(
                            onTap: () async {
                              final Uri url = Uri.parse(fileLink!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: const Text(
                              "View Case File",
                              style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      if (caseTextToShow != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            caseTextToShow!,
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButton<Map<String, dynamic>>(
                          hint: const Text("Select Time Slot"),
                          value: selectedSlot,
                          onChanged: (value) {
                            setState(() {
                              selectedSlot = value;
                            });
                          },
                          items: tempSlots.map((slot) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: slot,
                              child: Text(
                                  "${slot['date']} ${slot['start_time']} - ${slot['end_time']}"),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Enter Prosecutor's Email",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: confirmSlot,
                          child: const Text("Confirm Slot"),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Cancel Slot Selection"),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
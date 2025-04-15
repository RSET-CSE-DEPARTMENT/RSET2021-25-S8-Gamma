/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:legal/slot_confirmation_page.dart';

class ReferenceLoginPage extends StatefulWidget {
  const ReferenceLoginPage({super.key});

  @override
  _ReferenceLoginPageState createState() => _ReferenceLoginPageState();
}

class _ReferenceLoginPageState extends State<ReferenceLoginPage> {
  final TextEditingController _referenceIdController = TextEditingController();
  final TextEditingController _passKeyController = TextEditingController();
  String? _errorMessage;

  Future<void> _validateCase() async {
    final String referenceId = _referenceIdController.text;
    final String passKey = _passKeyController.text;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/validate_case'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reference_id': referenceId,
        'pass_key': passKey,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaseDetailsPage(
            caseId: data['case_id'],

            // Pass additional data if needed
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = jsonDecode(response.body)['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Reference and Pass Key")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _referenceIdController,
              decoration: const InputDecoration(labelText: "Reference ID"),
            ),
            TextField(
              controller: _passKeyController,
              decoration: const InputDecoration(labelText: "Pass Key"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _validateCase,
              child: const Text("View Petition"), // Changed button text
            ),
          ],
        ),
      ),
    );
  }
}

class CaseDetailsPage extends StatelessWidget {
  final int caseId;

  const CaseDetailsPage({
    super.key,
    required this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Case ID: $caseId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            //const Text("Case Details:"),
            // Text(caseDetails),
            const SizedBox(height: 20),
            // Placeholder for viewing the petition
            const Text(
              "Viewing Petition...",
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
            const Spacer(),
            // Confirm Slots button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SlotConfirmationPage(caseId: caseId),
                  ),
                );
              },
              child: const Text("Confirm Slots"),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:legal/slot_confirmation_page.dart';
import 'UserData.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class ReferenceLoginPage extends StatefulWidget {
  const ReferenceLoginPage({super.key});

  @override
  _ReferenceLoginPageState createState() => _ReferenceLoginPageState();
}

class _ReferenceLoginPageState extends State<ReferenceLoginPage> {
  final TextEditingController _referenceIdController = TextEditingController();
  final TextEditingController _passKeyController = TextEditingController();
  String? _errorMessage;

  Future<void> _validateCase() async {
    final String referenceId = _referenceIdController.text;
    final String passKey = _passKeyController.text;

    final userData = Provider.of<UserData>(context, listen: false);

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/validate_case'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reference_id': referenceId,
        'pass_key': passKey,
        'user_id': userData.userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaseDetailsPage(
            caseId: data['case_id'],
            fileId: data['file_id'], // Pass file ID
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = jsonDecode(response.body)['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Reference and Pass Key")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _referenceIdController,
              decoration: const InputDecoration(labelText: "Reference ID"),
            ),
            TextField(
              controller: _passKeyController,
              decoration: const InputDecoration(labelText: "Pass Key"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _validateCase,
              child: const Text("View Petition"),
            ),
          ],
        ),
      ),
    );
  }
}

class CaseDetailsPage extends StatelessWidget {
  final int caseId;
  final String fileId;

  const CaseDetailsPage({
    super.key,
    required this.caseId,
    required this.fileId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Case ID: $caseId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final url =
                    'https://drive.google.com/file/d/$fileId/view?usp=sharing';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: const Text(
                "View Petition",
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SlotConfirmationPage(caseId: caseId),
                  ),
                );
              },
              child: const Text("Confirm Slots"),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // Import Provider
import 'package:legal/slot_confirmation_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'UserData.dart'; // Import your UserData class

class ReferenceLoginPage extends StatefulWidget {
  const ReferenceLoginPage({super.key});

  @override
  _ReferenceLoginPageState createState() => _ReferenceLoginPageState();
}

class _ReferenceLoginPageState extends State<ReferenceLoginPage> {
  final TextEditingController _referenceIdController = TextEditingController();
  final TextEditingController _passKeyController = TextEditingController();
  String? _errorMessage;

  Future<void> _validateCase() async {
    final String referenceId = _referenceIdController.text;
    final String passKey = _passKeyController.text;

    if (referenceId.isEmpty || passKey.isEmpty) {
      setState(() {
        _errorMessage = "Reference ID and Pass Key are required.";
      });
      return;
    }

    final userData = Provider.of<UserData>(context, listen: false);

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/validate_case'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reference_id': referenceId,
        'pass_key': passKey,
        'user_id': userData.userId, // Include user_id
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaseDetailsPage(
            caseId: data['case_id'],
            fileId: data['file_id'], // Pass file ID
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = jsonDecode(response.body)['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Reference and Pass Key")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _referenceIdController,
              decoration: const InputDecoration(labelText: "Reference ID"),
            ),
            TextField(
              controller: _passKeyController,
              decoration: const InputDecoration(labelText: "Pass Key"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _validateCase,
              child: const Text("View Petition"),
            ),
          ],
        ),
      ),
    );
  }
}

class CaseDetailsPage extends StatelessWidget {
  final int caseId;
  final String fileId;

  const CaseDetailsPage({
    super.key,
    required this.caseId,
    required this.fileId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Case ID: $caseId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final Uri url = Uri.parse(
                    'https://drive.google.com/file/d/$fileId/view?usp=sharing');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: const Text(
                "View Petition",
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SlotConfirmationPage(caseId: caseId),
                  ),
                );
              },
              child: const Text("Confirm Slots"),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // Import Provider
import 'package:legal/slot_confirmation_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'UserData.dart'; // Import your UserData class

class ReferenceLoginPage extends StatefulWidget {
  const ReferenceLoginPage({super.key});

  @override
  _ReferenceLoginPageState createState() => _ReferenceLoginPageState();
}

class _ReferenceLoginPageState extends State<ReferenceLoginPage> {
  final TextEditingController _referenceIdController = TextEditingController();
  final TextEditingController _passKeyController = TextEditingController();
  String? _errorMessage;

  Future<void> _validateCase() async {
    final String referenceId = _referenceIdController.text;
    final String passKey = _passKeyController.text;

    if (referenceId.isEmpty || passKey.isEmpty) {
      setState(() {
        _errorMessage = "Reference ID and Pass Key are required.";
      });
      return;
    }

    final userData = Provider.of<UserData>(context, listen: false);

    print(
        "Sending request with referenceId: $referenceId, passKey: $passKey, userId: ${userData.userId}");

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/validate_case'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reference_id': referenceId,
        'pass_key': passKey,
        'user_id': userData.userId, // Include user_id
      }),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Received caseId: ${data['case_id']}, fileId: ${data['file_id']}");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaseDetailsPage(
            caseId: data['case_id'],
            fileId: data['file_id'], // Pass file ID
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = jsonDecode(response.body)['message'];
        print("Error message: $_errorMessage");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Reference and Pass Key")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _referenceIdController,
              decoration: const InputDecoration(labelText: "Reference ID"),
            ),
            TextField(
              controller: _passKeyController,
              decoration: const InputDecoration(labelText: "Pass Key"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _validateCase,
              child: const Text("View Petition"),
            ),
          ],
        ),
      ),
    );
  }
}

class CaseDetailsPage extends StatelessWidget {
  final int caseId;
  final String fileId;

  const CaseDetailsPage({
    super.key,
    required this.caseId,
    required this.fileId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Case ID: $caseId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final Uri url = Uri.parse(
                    'https://drive.google.com/file/d/$fileId/view?usp=sharing');
                print("Opening URL: $url");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  print('Could not launch $url');
                }
              },
              child: const Text(
                "View Petition",
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                print(
                    "Navigating to SlotConfirmationPage with caseId: $caseId");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SlotConfirmationPage(caseId: caseId),
                  ),
                );
              },
              child: const Text("Confirm Slots"),
            ),
          ],
        ),
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // Import Provider
import 'package:legal/slot_confirmation_page.dart';
import 'UserData.dart'; // Import your UserData class

class ReferenceLoginPage extends StatefulWidget {
  const ReferenceLoginPage({super.key});

  @override
  _ReferenceLoginPageState createState() => _ReferenceLoginPageState();
}

class _ReferenceLoginPageState extends State<ReferenceLoginPage> {
  final TextEditingController _referenceIdController = TextEditingController();
  final TextEditingController _passKeyController = TextEditingController();
  String? _errorMessage;

  Future<void> _validateCase() async {
    final String referenceId = _referenceIdController.text;
    final String passKey = _passKeyController.text;

    if (referenceId.isEmpty || passKey.isEmpty) {
      setState(() {
        _errorMessage = "Reference ID and Pass Key are required.";
      });
      return;
    }

    final userData = Provider.of<UserData>(context, listen: false);

    print(
        "Sending request with referenceId: $referenceId, passKey: $passKey, userId: ${userData.userId}");

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/validate_case'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reference_id': referenceId,
        'pass_key': passKey,
        'user_id': userData.userId, // Include user_id
      }),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Received caseId: ${data['case_id']}");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SlotConfirmationPage(caseId: data['case_id']),
        ),
      );
    } else {
      setState(() {
        _errorMessage = jsonDecode(response.body)['message'];
        print("Error message: $_errorMessage");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Reference and Pass Key")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _referenceIdController,
              decoration: const InputDecoration(labelText: "Reference ID"),
            ),
            TextField(
              controller: _passKeyController,
              decoration: const InputDecoration(labelText: "Pass Key"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _validateCase,
              child: const Text("View Petition"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'slot_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'UserData.dart'; // Import UserData provider
import 'package:url_launcher/url_launcher.dart';

class SendEmailPage extends StatefulWidget {
  @override
  _SendEmailPageState createState() => _SendEmailPageState();
}

class _SendEmailPageState extends State<SendEmailPage> {
  final TextEditingController caseNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  File? _file;
  String referenceId = '';
  String passkey = '';
  String? fileId;
  String? fileLink;
  String? textFileLink;

  // ✅ Generate Reference ID and Passkey
  void generateReferenceAndPasskey() {
    setState(() {
      referenceId = _generateRandomString(8);
      passkey = _generateRandomString(8);
    });
  }

  // ✅ Helper Function to Generate Random String
  String _generateRandomString(int length) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }

  // ✅ File Picker Function
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    } else {
      print("No file selected");
    }
  }

  // ✅ Upload File and Process OCR
  Future<void> _uploadFileAndProcessOCR(BuildContext context) async {
    if (_file == null) {
      print("No file to upload");
      return;
    }

    final userData = Provider.of<UserData>(context, listen: false);
    if (userData.caseId == null) {
      print("⚠️ Case ID is null");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Case ID is missing.")),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:5000/upload-and-process-ocr'),
    );

    // Add file
    request.files.add(await http.MultipartFile.fromPath('file', _file!.path));

    // ✅ Add case ID to the form data
    request.fields['case_id'] = userData.caseId.toString();

    try {
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("🚀 Response Status Code: ${response.statusCode}");
      print("📜 Full Response Body: $responseBody");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);

        if (jsonResponse.containsKey('text_file_path')) {
          textFileLink = jsonResponse['text_file_path'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("File uploaded and OCR processed!")),
          );

          Future.microtask(() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SlotSelectionPage()),
            );
          });
        } else {
          print("❌ 'text_file_path' missing in response!");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("Server response does not contain text file path")),
          );
        }
      } else {
        print("❌ Failed to upload file. Server Response: $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload file")),
        );
      }
    } catch (e) {
      print("🔥 Exception Occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading file: $e")),
      );
    }
  }

  // ✅ Save File ID to Case
  Future<void> _saveFileId(String fileId, int caseId) async {
    final url = Uri.parse('http://127.0.0.1:5000/savefileid');
    try {
      final requestBody = {"file_id": fileId, "case_id": caseId};
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        print("File ID saved successfully");
      } else {
        print("Failed to save file ID: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // ✅ Submit Case Details
  Future<void> sendCaseDetails(BuildContext context) async {
    if (caseNameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final userData = Provider.of<UserData>(context, listen: false);
    final url = Uri.parse('http://127.0.0.1:5000/store-case');
    final requestBody = {
      'case_name': caseNameController.text,
      'defendant_email': emailController.text,
      'reference_id': referenceId,
      'passkey': passkey,
      'user_id': userData.userId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final caseId = responseData['case_id'];
        userData.caseId = caseId;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Case submitted successfully! Case ID: $caseId')),
          );
        }
        await sendEmail(emailController.text);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit case details.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ✅ Send Email
  Future<void> sendEmail(String email) async {
    final url = Uri.parse('http://127.0.0.1:5000/send-email');
    try {
      final requestBody = {
        "defendant_email": email,
        "reference_id": referenceId,
        "passkey": passkey,
      };
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Email sent successfully!")),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send email: ${response.body}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Start a new case')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: caseNameController,
                decoration: InputDecoration(labelText: 'Case Name')),
            TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Defendant Email')),
            ElevatedButton(
                onPressed: generateReferenceAndPasskey,
                child: Text('Generate Reference ID & Passkey')),
            Text('Reference ID: $referenceId\nPasskey: $passkey'),
            ElevatedButton(
                onPressed: () => sendCaseDetails(context),
                child: Text('Submit Case')),
            ElevatedButton(onPressed: _pickFile, child: Text("Pick PDF File")),
            ElevatedButton(
                onPressed: () => _uploadFileAndProcessOCR(context),
                child: Text("Upload File")),
          ],
        ),
      ),
    );
  }
}

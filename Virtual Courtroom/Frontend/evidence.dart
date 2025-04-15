import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AudioToTextPage.dart';

class EvidenceUploadPage extends StatefulWidget {
  final int caseId;

  const EvidenceUploadPage({super.key, required this.caseId});

  @override
  _EvidenceUploadPageState createState() => _EvidenceUploadPageState();
}

class _EvidenceUploadPageState extends State<EvidenceUploadPage> {
  String _predictionResult = "No file selected";
  bool _isLoading = false;

  Future<void> _pickFile(String userType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      _uploadFile(file, userType);
    }
  }

  Future<void> _uploadFile(File file, String userType) async {
    setState(() {
      _isLoading = true;
      _predictionResult = "Processing...";
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:5000/predict'),
    );

    request.fields['caseId'] = widget.caseId.toString();
    request.fields['userType'] = userType;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        setState(() {
          _predictionResult =
              "$userType Evidence (Case ${widget.caseId}): ${jsonResponse['prediction']}";
        });
      } else {
        setState(() {
          _predictionResult = "Error: Failed to process image.";
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = "Error: Unable to connect to server.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToAudioToText() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioToTextPage(caseId: widget.caseId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Evidence - Case ${widget.caseId}"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _pickFile("Prosecutor"),
              child: const Text("Upload Prosecutor Evidence"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickFile("Defense"),
              child: const Text("Upload Defense Evidence"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToAudioToText,
              child: const Text("Go to Audio to Text Page"),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    _predictionResult,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ],
        ),
      ),
    );
  }
}

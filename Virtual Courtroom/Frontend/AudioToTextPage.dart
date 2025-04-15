import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AudioToTextPage extends StatefulWidget {
  final int caseId;

  const AudioToTextPage({super.key, required this.caseId});

  @override
  _AudioToTextPageState createState() => _AudioToTextPageState();
}

class _AudioToTextPageState extends State<AudioToTextPage> {
  bool _isListening = false;
  bool _isLoading = false;
  String _text = "Tap the mic and start speaking";

  final ScrollController _scrollController = ScrollController(); // ✅ added
  final String flaskUrl = "http://127.0.0.1:5000";

  Future<void> _startRecording() async {
    try {
      final response = await http.get(Uri.parse("$flaskUrl/start_recording"));
      if (response.statusCode == 200) {
        setState(() {
          _isListening = true;
          _text = "Recording... Speak now!";
        });
      } else {
        _showError("Failed to start recording");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isLoading = true;
      _isListening = false;
      _text = "Processing transcription...";
    });

    try {
      final response = await http.get(Uri.parse("$flaskUrl/stop_recording"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Transcription Response: $data");

        if (data['transcription'] != null) {
          setState(() {
            _isLoading = false;
            _text = data['transcription']
                .toString(); // Keep formatting as is from backend
          });
        } else {
          _showError("Transcription successful");
        }
      } else {
        _showError("Failed to stop recording");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _toggleRecording() {
    if (_isListening) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _text = message;
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅ dispose scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio-to-Text Feature')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _isLoading
                    ? Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text(
                            "Transcribing...",
                            style: GoogleFonts.montserrat(
                                fontSize: 18, color: Colors.black),
                          ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Text(
                          _text,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.justify, // ✅ Justified output
                        ),
                      ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _toggleRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isListening ? 'Stop Listening' : 'Start Listening',
                    style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

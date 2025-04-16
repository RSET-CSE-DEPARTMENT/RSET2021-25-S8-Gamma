import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AudioToTextPage.dart';

class Judgefirstpg extends StatelessWidget {
  const Judgefirstpg({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booked Cases',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BookedCasesPage(),
    );
  }
}

class BookedCasesPage extends StatefulWidget {
  const BookedCasesPage({super.key});

  @override
  State<BookedCasesPage> createState() => _BookedCasesPageState();
}

class _BookedCasesPageState extends State<BookedCasesPage> {
  List<Map<String, dynamic>> bookedCases = [];

  @override
  void initState() {
    super.initState();
    fetchBookedCases();
  }

  Future<void> fetchBookedCases() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:5000/get_booked_cases'));
    if (response.statusCode == 200) {
      setState(() {
        bookedCases =
            List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      throw Exception('Failed to load booked cases');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booked Cases Today')),
      body: bookedCases.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: bookedCases.length,
              itemBuilder: (context, index) {
                final caseData = bookedCases[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Case ID: ${caseData['case_id']}"),
                    subtitle: Text(
                        "${caseData['case_name']} \n${caseData['start_time']} - ${caseData['end_time']}"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ViewPetitionPage(caseId: caseData['case_id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class ViewPetitionPage extends StatefulWidget {
  final int caseId;

  const ViewPetitionPage({super.key, required this.caseId});

  @override
  _ViewPetitionPageState createState() => _ViewPetitionPageState();
}

class _ViewPetitionPageState extends State<ViewPetitionPage> {
  String? petitionText; // To store the fetched petition text
  bool isLoading = true; // Loading state
  String? errorMessage; // Error message

  // Fetch the petition text from the backend
  Future<void> fetchCasePetition() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/get_case_text'), // Backend endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'case_id': widget.caseId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          petitionText = data['case_text']; // Store the fetched petition text
          isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching petition: $e';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCasePetition(); // Fetch petition text when page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Petition - Case ${widget.caseId}')),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading indicator
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!), // Show error message if present
                )
              : SingleChildScrollView(
                  // Wrap content with SingleChildScrollView to enable scrolling
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petitionText ??
                            'No petition details found for this case.',
                        textAlign: TextAlign.justify, // Justify text alignment
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AudioToTextPage(caseId: widget.caseId)),
                          );
                        },
                        child: const Text('Start Meeting'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

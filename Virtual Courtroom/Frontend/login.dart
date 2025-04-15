import 'package:flutter/material.dart';
import 'package:legal/JudgeFirstPg.dart';
import 'package:provider/provider.dart';
import 'UserData.dart'; // Import your provider here
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DashboardPage.dart'; // Import the Dashboard Page here
import 'SignUpPage.dart'; // Import the SignUp Page here

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class LegalAppColors {
  static const Color primaryColor =
      Color.fromARGB(255, 33, 84, 136); // Navy Blue (Headers, Navigation)
  static const Color accentColor =
      Color(0xFFC8A415); // Gold (Highlights, Buttons)
  static const Color textColor = Color(0xFF2E2E2E); // Dark Gray (Text)
  static const Color backgroundColor = Color(0xFFFFFFFF); // White (Background)
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    const url = 'http://127.0.0.1:5000/login';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Update the UserData provider
      Provider.of<UserData>(context, listen: false).userId = data['user_id'];
      Provider.of<UserData>(context, listen: false).isJudge = data['is_judge'];

      // Check if the user is a judge
      if (data['is_judge'] == true) {
        // If user is a judge, print "hello" on the terminal
        print('Hello');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Judgefirstpg()),
        );
      } else {
        // If user is not a judge, navigate to the Dashboard Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      }
    } else {
      // Handle login error
      print('Login failed: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: LegalAppColors.primaryColor,
      ),
      backgroundColor: LegalAppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: LegalAppColors.textColor),
              ),
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: LegalAppColors.textColor),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: LegalAppColors.textColor),
              ),
              obscureText: true,
              style: TextStyle(color: LegalAppColors.textColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    LegalAppColors.primaryColor, // Dark Green Button
                foregroundColor: Colors.white,
              ),
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text(
                "Don't have an account? Sign Up",
                style: TextStyle(
                    color: LegalAppColors.accentColor), // Burgundy Text
              ),
            ),
          ],
        ),
      ),
    );
  }
}

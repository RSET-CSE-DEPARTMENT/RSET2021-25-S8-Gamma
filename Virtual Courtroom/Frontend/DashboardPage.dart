import 'package:flutter/material.dart';
// import 'package:legal/newCase.dart';
import 'package:legal/reference_login_page.dart';
import 'package:legal/send_email.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to the AddNewCasePage when pressed
                // Uncomment and update the following line with the correct import
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SendEmailPage()),
                );
              },
              child: const Column(
                children: [
                  Icon(
                    Icons.add_circle,
                    size: 80,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'New Case',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReferenceLoginPage()),
                );
              },
              child: const Column(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 80,
                    color: Colors.green,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Defense',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

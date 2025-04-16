import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'UserData.dart';
import 'login.dart'; // Import your LoginPage here
import 'DashboardPage.dart'; // Import your DashboardPage here

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserData()), // Provide UserData
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Courtroom App',
      debugShowCheckedModeBanner: false, // 👈 Disable debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/dashboard': (context) => DashboardPage(),
      },
    );
  }
}

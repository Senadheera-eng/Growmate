import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(GrowMateApp());
}

class GrowMateApp extends StatelessWidget {
  final Map<String, String> userAccounts = {};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GrowMate-Plant Companion!!',
      theme: ThemeData(primarySwatch: Colors.green),
      home: LoginPage(userAccounts: userAccounts),
    );
  }
}

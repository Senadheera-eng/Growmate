import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

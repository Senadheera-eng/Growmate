import 'package:flutter/material.dart';

class MyTreesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Trees',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text(
          'Manage Your Trees Here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

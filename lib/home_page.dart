import 'package:flutter/material.dart';
import 'drag_and_drop_section.dart';
import 'my_trees_section.dart';
import 'tips_section.dart';
import 'settings_section.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DragAndDropSection(),
    MyTreesSection(),
    TipsSection(),
    SettingsSection(
      onThemeChange: (bool value) {},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GrowMate',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.teal.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Switch Account') {
                // Handle Switch Account
              } else if (value == 'Create Account') {
                // Handle Create Account
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Switch Account', 'Create Account'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'My Trees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

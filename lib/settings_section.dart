import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final ValueChanged<bool> onThemeChange;

  const SettingsSection({Key? key, required this.onThemeChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Roboto'),
        ),
        backgroundColor: Colors.greenAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Dark Mode', style: TextStyle(fontSize: 18)),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: onThemeChange,
            ),
            Divider(),
            ListTile(
              title:
                  Text('Manage Notifications', style: TextStyle(fontSize: 18)),
              leading: Icon(Icons.notifications),
              onTap: () {
                // TODO: Navigate to Notifications settings
              },
            ),
            Divider(),
            ListTile(
              title: Text('Account Settings', style: TextStyle(fontSize: 18)),
              leading: Icon(Icons.account_circle),
              onTap: () {
                // TODO: Navigate to Account settings
              },
            ),
            Divider(),
            ListTile(
              title: Text('Logout',
                  style: TextStyle(fontSize: 18, color: Colors.red)),
              leading: Icon(Icons.logout, color: Colors.red),
              onTap: () {
                // TODO: Implement Logout functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}

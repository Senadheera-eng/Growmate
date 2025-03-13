// notification_settings_page.dart
import 'package:flutter/material.dart';
import 'notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _wateringReminders = true;
  bool _fertilizationReminders = true;
  bool _careTipsReminders = true;
  bool _treatmentReminders = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _notificationService.getNotificationPreferences();

    setState(() {
      _wateringReminders = prefs['watering'] ?? true;
      _fertilizationReminders = prefs['fertilization'] ?? true;
      _careTipsReminders = prefs['care_tips'] ?? true;
      _treatmentReminders = prefs['treatment'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    await _notificationService.saveNotificationPreferences(
      wateringReminders: _wateringReminders,
      fertilizationReminders: _fertilizationReminders,
      careTipsReminders: _careTipsReminders,
      treatmentReminders: _treatmentReminders,
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 12),
            Text('Notification preferences saved'),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 5, 158, 69),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade400, Colors.green.shade700],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Notification Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Main Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, -4),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: 20),
                                  _buildNotificationSection(
                                    title: 'Watering Reminders',
                                    subtitle: 'Remind me when it\'s time to water my trees',
                                    icon: Icons.opacity_rounded,
                                    color: Colors.blue,
                                    value: _wateringReminders,
                                    onChanged: (value) {
                                      setState(() => _wateringReminders = value);
                                    },
                                  ),
                                  _buildNotificationSection(
                                    title: 'Fertilization Reminders',
                                    subtitle:
                                        'Remind me when it\'s time to fertilize my trees',
                                    icon: Icons.eco_rounded,
                                    color: Colors.green,
                                    value: _fertilizationReminders,
                                    onChanged: (value) {
                                      setState(() => _fertilizationReminders = value);
                                    },
                                  ),
                                  _buildNotificationSection(
                                    title: 'Care Tips Reminders',
                                    subtitle: 'Remind me about other care tasks for my trees',
                                    icon: Icons.tips_and_updates_rounded,
                                    color: Colors.amber,
                                    value: _careTipsReminders,
                                    onChanged: (value) {
                                      setState(() => _careTipsReminders = value);
                                    },
                                  ),
                                  _buildNotificationSection(
                                    title: 'Treatment Reminders',
                                    subtitle:
                                        'Remind me to continue treatment steps for diseased trees',
                                    icon: Icons.healing_rounded,
                                    color: Colors.red,
                                    value: _treatmentReminders,
                                    onChanged: (value) {
                                      setState(() => _treatmentReminders = value);
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  _buildSaveButton(),
                                  const SizedBox(height: 16),
                                  _buildRefreshButton(),
                                  const SizedBox(height: 16),
                                  _buildTestNotificationButton(),
                                  const SizedBox(height: 30),
                                  _buildNotificationInfo(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        value: value,
        activeColor: const Color(0xFF00C853),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00C853),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Preferences',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: TextButton.icon(
        onPressed: () async {
          setState(() => _isLoading = true);
          await _notificationService.refreshAllNotifications();
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.white),
                  SizedBox(width: 12),
                  Text('All notifications have been refreshed'),
                ],
              ),
              backgroundColor: const Color.fromARGB(255, 5, 158, 69),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
        icon: const Icon(
          Icons.refresh_rounded,
          color: Color(0xFF00C853),
        ),
        label: const Text(
          'Refresh All Notifications',
          style: TextStyle(
            color: Color(0xFF424242),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade300,
          width: 1,
        ),
      ),
      child: TextButton.icon(
        onPressed: () async {
          // Schedule a notification 5 seconds from now
          final notificationTime = DateTime.now().add(Duration(seconds: 5));

          await NotificationService().scheduleTestNotification();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Test notification scheduled Now!'),
                ],
              ),
              backgroundColor: const Color.fromARGB(255, 5, 158, 69),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
        icon: const Icon(
          Icons.notifications_active,
          color: Colors.blue,
        ),
        label: const Text(
          'Test Notification Now',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'About Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'GrowMate will send you reminders based on your tree\'s needs:\n'
            '• Watering: Based on tree age and last watering date\n'
            '• Fertilization: Every 3-6 weeks depending on tree age\n'
            '• Care Tips: General tree care advice\n'
            '• Treatment: Progress and scheduled steps for diseased trees',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00C853),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Notification Preferences',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize your tree care reminders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
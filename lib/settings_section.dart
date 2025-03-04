import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'login_page.dart';

class SettingsSection extends StatefulWidget {
  final ValueChanged<bool> onThemeChange;

  const SettingsSection({Key? key, required this.onThemeChange})
      : super(key: key);

  @override
  _SettingsSectionState createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _appVersion = '1.0.0';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserData();
    _getAppVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setBool('notifications', _notificationsEnabled);
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _profileImageUrl = userDoc.get('profileImageUrl');
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      print('Error getting app version: $e');
    }
  }

  Future<void> _handleDarkModeChange(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    widget.onThemeChange(value);
    await _saveSettings();
  }

  Future<void> _handleNotificationsChange(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    // Update notifications permission and settings
    await _updateNotificationSettings(value);
    await _saveSettings();
  }

  Future<void> _updateNotificationSettings(bool enabled) async {
    // This would normally use a notification plugin to request/update permissions
    // For this example, we're just saving the preference

    // If you're using firebase messaging, the code would be something like:
    // final firebaseMessaging = FirebaseMessaging.instance;
    // if (enabled) {
    //   await firebaseMessaging.requestPermission();
    // } else {
    //   // Note: On iOS, users must disable notifications via system settings
    //   // On Android, we can't programmatically disable notifications completely
    // }

    // Save the preference to user's profile
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'notificationsEnabled': enabled,
      });
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _auth.signOut();
      // Navigate to login page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error signing out. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSettingItem(
                    title: 'Dark Mode',
                    icon: Icons.dark_mode_outlined,
                    isSwitch: true,
                    currentValue: _isDarkMode,
                    onChanged: _handleDarkModeChange,
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'Manage Notifications',
                    subtitle: 'Control app notifications',
                    icon: Icons.notifications_outlined,
                    isSwitch: true,
                    currentValue: _notificationsEnabled,
                    onChanged: _handleNotificationsChange,
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'Account Settings',
                    subtitle: 'Manage your account information',
                    icon: Icons.account_circle_outlined,
                    onTap: () {
                      _navigateToAccountSettings();
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy settings',
                    icon: Icons.security_outlined,
                    onTap: () {
                      _navigateToPrivacySettings();
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'About GrowMate',
                    subtitle: 'Version $_appVersion',
                    icon: Icons.info_outline,
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'Help & Support',
                    subtitle: 'Get assistance with the app',
                    icon: Icons.help_outline,
                    onTap: () {
                      _navigateToHelpSupport();
                    },
                  ),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildLogoutButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 22,
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize your GrowMate experience',
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

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required IconData icon,
    bool isSwitch = false,
    bool? currentValue,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00C853).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00C853),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            : null,
        trailing: isSwitch
            ? Switch(
                value: currentValue ?? false,
                onChanged: onChanged,
                activeColor: const Color(0xFF00C853),
                activeTrackColor: const Color(0xFF00C853).withOpacity(0.3),
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
        onTap: isSwitch ? null : onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 16,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade300,
            Colors.red.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleSignOut,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAccountSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSettingsPage(
          onProfileUpdated: () => _loadUserData(),
        ),
      ),
    );
  }

  void _navigateToPrivacySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsPage(),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('About GrowMate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF00C853),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GrowMate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                'Version $_appVersion',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GrowMate helps you care for your plants with disease detection, care reminders, and growth tracking.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} GrowMate Team',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpSupportPage(),
      ),
    );
  }
}

class AccountSettingsPage extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  const AccountSettingsPage({Key? key, required this.onProfileUpdated})
      : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _profileImageUrl;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    User? user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';

      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _profileImageUrl = userData['profileImageUrl'];
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Upload new profile image if selected
        String? imageUrl = _profileImageUrl;
        if (_selectedImage != null) {
          final storageRef = _storage.ref().child('profile_images/${user.uid}');
          await storageRef.putFile(_selectedImage!);
          imageUrl = await storageRef.getDownloadURL();
        }

        // Update user profile in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'profileImageUrl': imageUrl,
        });

        // Update email if changed
        if (user.email != _emailController.text.trim() &&
            _emailController.text.trim().isNotEmpty) {
          await user.updateEmail(_emailController.text.trim());
        }

        widget.onProfileUpdated();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: const Color(0xFF00C853),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Profile Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : _profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                          child:
                              _profileImageUrl == null && _selectedImage == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name Field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF00C853),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF00C853),
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 24),

                  // Update Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password Change Option
                  TextButton(
                    onPressed: () {
                      // Navigate to change password screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Change Password'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Validate inputs
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Re-authenticate user
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Change password
        await user.updatePassword(_newPasswordController.text);

        if (mounted) {
          _showSuccessSnackBar('Password changed successfully');

          // Navigate back after short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }

    setState(() => _isLoading = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00C853),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: const Color(0xFF00C853),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change your password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your current password and a new password to update your credentials.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Password Field
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // New Password Field
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Confirm Password Field
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Update Password Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Update Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({Key? key}) : super(key: key);

  @override
  _PrivacySettingsPageState createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _locationEnabled = true;
  bool _analyticsSharingEnabled = true;
  bool _allowDataCollection = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('privacySettings').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _locationEnabled = data['locationEnabled'] ?? true;
            _analyticsSharingEnabled = data['analyticsSharingEnabled'] ?? true;
            _allowDataCollection = data['allowDataCollection'] ?? true;
          });
        } else {
          // Create default privacy settings if they don't exist
          await _firestore.collection('privacySettings').doc(user.uid).set({
            'locationEnabled': true,
            'analyticsSharingEnabled': true,
            'allowDataCollection': true,
          });
        }
      }
    } catch (e) {
      print('Error loading privacy settings: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updatePrivacySetting(String setting, bool value) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('privacySettings').doc(user.uid).update({
          setting: value,
        });

        // Apply the setting
        switch (setting) {
          case 'locationEnabled':
            setState(() => _locationEnabled = value);
            break;
          case 'analyticsSharingEnabled':
            setState(() => _analyticsSharingEnabled = value);
            break;
          case 'allowDataCollection':
            setState(() => _allowDataCollection = value);
            break;
        }
      }
    } catch (e) {
      print('Error updating privacy setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: const Color(0xFF00C853),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Location Permission
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Allow the app to access your location for better plant recommendations based on your climate zone.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _locationEnabled,
                          onChanged: (value) =>
                              _updatePrivacySetting('locationEnabled', value),
                          title: const Text('Enable Location'),
                          activeColor: const Color(0xFF00C853),
                        ),
                      ],
                    ),
                  ),
                ),

                // Analytics Sharing
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usage Analytics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share anonymous usage data to help us improve GrowMate. No personal information is shared.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _analyticsSharingEnabled,
                          onChanged: (value) => _updatePrivacySetting(
                              'analyticsSharingEnabled', value),
                          title: const Text('Share Analytics'),
                          activeColor: const Color(0xFF00C853),
                        ),
                      ],
                    ),
                  ),
                ),

                // Data Collection
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Plant Data Collection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Allow GrowMate to collect data about your plants to improve disease detection and care recommendations.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _allowDataCollection,
                          onChanged: (value) => _updatePrivacySetting(
                              'allowDataCollection', value),
                          title: const Text('Allow Data Collection'),
                          activeColor: const Color(0xFF00C853),
                        ),
                      ],
                    ),
                  ),
                ),

                // Data Policy Link
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.policy_outlined,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Review our data handling practices'),
                    onTap: () {
                      // Launch privacy policy page
                      _showPrivacyPolicy();
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () {
                      // Show delete account dialog
                      _showDeleteAccountDialog();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Delete My Account',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GrowMate Privacy Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'At GrowMate, we take your privacy seriously. This policy describes how we collect, use, and share your information.',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Information We Collect',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Account information: email, name, profile picture\n'
                  '• Plant data: images, care activities, growth records\n'
                  '• Optional: location data for climate recommendations\n'
                  '• Usage data: app interactions, features used, time spent',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How We Use Your Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Provide personalized plant care recommendations\n'
                  '• Improve disease detection algorithms\n'
                  '• Enhance app features and user experience\n'
                  '• Send care reminders and important notifications',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Rights',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can access, update, or delete your personal information at any time through app settings. You can also adjust privacy settings or opt out of certain data collection.',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        await _firestore.collection('privacySettings').doc(user.uid).delete();

        // Delete the user account
        await user.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );

          // Navigate to login page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFF00C853),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFaqItem(
                  'How does plant detection work?',
                  'GrowMate uses advanced image recognition technology to identify plants and detect diseases. Simply take a clear photo of your plant, and our AI will analyze it to provide information and care recommendations.',
                ),
                const Divider(),
                _buildFaqItem(
                  'Can I use GrowMate offline?',
                  'Some features like viewing your saved plants and care schedules work offline. However, plant identification, disease detection, and community features require an internet connection.',
                ),
                const Divider(),
                _buildFaqItem(
                  'How accurate is disease detection?',
                  'Our disease detection system is continuously improving. Currently, it can identify common plant diseases with approximately 85-90% accuracy. Always double-check with trusted sources for serious plant health concerns.',
                ),
                const Divider(),
                _buildFaqItem(
                  'How can I back up my plant data?',
                  'All your data is automatically backed up to your account in the cloud. If you switch devices, simply log in with the same account to access all your plants and history.',
                ),
              ],
            ),
          ),

          // Contact Support
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    title: const Text('Email Support'),
                    subtitle: const Text('support@growmate.app'),
                    onTap: () {
                      // Open email client
                      // In a real app, integrate email sending functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Opening email client...')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chat_outlined,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    title: const Text('Live Chat'),
                    subtitle: const Text('Available 9AM-5PM EST, Mon-Fri'),
                    onTap: () {
                      _showLiveChatUnavailable(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Tutorials Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Tutorials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTutorialItem(
                    context,
                    'How to Identify Plants',
                    'Learn how to use the plant identification feature',
                    Icons.eco_outlined,
                    Colors.green,
                  ),
                  const Divider(),
                  _buildTutorialItem(
                    context,
                    'Setting Up Care Reminders',
                    'Create custom care schedules for your plants',
                    Icons.notifications_outlined,
                    Colors.orange,
                  ),
                  const Divider(),
                  _buildTutorialItem(
                    context,
                    'Tracking Plant Growth',
                    'Keep a visual record of your plant\'s progress',
                    Icons.trending_up_outlined,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          // Community Forums
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  color: Color(0xFF00C853),
                ),
              ),
              title: const Text('Community Forums'),
              subtitle: const Text('Connect with other plant enthusiasts'),
              onTap: () {
                // Launch community forums
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Forums feature coming soon!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          answer,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.play_circle_outline),
      onTap: () {
        // Launch tutorial
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening tutorial: $title')),
        );
      },
    );
  }

  void _showLiveChatUnavailable(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Live Chat'),
          content: const Text(
            'Live chat support is currently unavailable. Please try again during our operating hours (9AM-5PM EST, Monday-Friday) or send us an email at support@growmate.app',
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final ValueChanged<bool> onThemeChange;

  const SettingsSection({Key? key, required this.onThemeChange})
      : super(key: key);

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
                    currentValue:
                        Theme.of(context).brightness == Brightness.dark,
                    onChanged: onThemeChange,
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'Manage Notifications',
                    subtitle: 'Control app notifications',
                    icon: Icons.notifications_outlined,
                    onTap: () {
                      // TODO: Navigate to Notifications settings
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'Account Settings',
                    subtitle: 'Manage your account information',
                    icon: Icons.account_circle_outlined,
                    onTap: () {
                      // TODO: Navigate to Account settings
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy settings',
                    icon: Icons.security_outlined,
                    onTap: () {
                      // TODO: Navigate to Privacy settings
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'About GrowMate',
                    subtitle: 'Version 1.0.0',
                    icon: Icons.info_outline,
                    onTap: () {
                      // TODO: Navigate to About page
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    title: 'Help & Support',
                    subtitle: 'Get assistance with the app',
                    icon: Icons.help_outline,
                    onTap: () {
                      // TODO: Navigate to Help page
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
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 22,
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
          onTap: () {
            // TODO: Implement Logout functionality
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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
}

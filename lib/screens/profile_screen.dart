// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String email = '';
  String namaAlat = '';
  String deviceId = '';
  String userId = '';
  String telepon = '';
  String alamat = '';
  bool notificationsEnabled = true;
  bool autoSyncEnabled = true;
  bool isLoading = true;
  int totalDevices = 0;
  String appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      setState(() {
        username = pref.getString('username') ?? 'User';
        email = pref.getString('email') ?? 'user@example.com';
        namaAlat = pref.getString('namaAlat') ?? 'Smart Farm Device';
        deviceId = pref.getString('deviceId') ?? 'N/A';
        userId =
            pref.getString('userId') ?? pref.getInt('id')?.toString() ?? 'N/A';
        telepon = pref.getString('telepon') ?? '';
        alamat = pref.getString('alamat') ?? '';
        notificationsEnabled = pref.getBool('notifications') ?? true;
        autoSyncEnabled = pref.getBool('autoSync') ?? true;
      });

      // Load additional device information
      await _loadDeviceInfo();
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      // This would typically fetch from your API
      // For now, we'll use mock data
      setState(() {
        totalDevices = 1; // Could be fetched from API
      });
    } catch (e) {
      print('Error loading device info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? _buildLoadingScreen()
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Profile Header
                  _buildProfileHeader(),

                  SizedBox(height: 24),

                  // Account Settings
                  _buildAccountSettings(),

                  SizedBox(height: 24),

                  // App Settings
                  _buildAppSettings(),

                  SizedBox(height: 24),

                  // Device Settings
                  _buildDeviceSettings(),

                  SizedBox(height: 24),

                  // Support & About
                  _buildSupportSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColor.hijau1),
          ),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColor.hijau2,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            username,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (telepon.isNotEmpty) ...[
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  telepon,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard("User ID", userId),
              _buildStatCard("Devices", totalDevices.toString()),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _navigateToEditProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.hijau1,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Edit Profile",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return _buildSettingsSection(
      title: "Account Settings",
      children: [
        _buildSettingsItem(
          icon: Icons.person,
          title: "Personal Information",
          subtitle: "Update your personal details",
          onTap: () {
            // TODO: Navigate to personal info
          },
        ),
        _buildSettingsItem(
          icon: Icons.security,
          title: "Security",
          subtitle: "Change password and security settings",
          onTap: () {
            // TODO: Navigate to security settings
          },
        ),
        _buildSettingsItem(
          icon: Icons.privacy_tip,
          title: "Privacy",
          subtitle: "Manage your privacy preferences",
          onTap: () {
            // TODO: Navigate to privacy settings
          },
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return _buildSettingsSection(
      title: "App Settings",
      children: [
        _buildSwitchItem(
          icon: Icons.notifications,
          title: "Notifications",
          subtitle: "Receive alerts and updates",
          value: notificationsEnabled,
          onChanged: (value) async {
            setState(() {
              notificationsEnabled = value;
            });
            SharedPreferences pref = await SharedPreferences.getInstance();
            await pref.setBool('notifications', value);
          },
        ),
        _buildSwitchItem(
          icon: Icons.sync,
          title: "Auto Sync",
          subtitle: "Automatically sync data",
          value: autoSyncEnabled,
          onChanged: (value) async {
            setState(() {
              autoSyncEnabled = value;
            });
            SharedPreferences pref = await SharedPreferences.getInstance();
            await pref.setBool('autoSync', value);
          },
        ),
        _buildSettingsItem(
          icon: Icons.language,
          title: "Language",
          subtitle: "Choose your preferred language",
          trailing: Text(
            "English",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          onTap: () {
            // TODO: Navigate to language settings
          },
        ),
      ],
    );
  }

  Widget _buildDeviceSettings() {
    return _buildSettingsSection(
      title: "Device Settings",
      children: [
        _buildSettingsItem(
          icon: Icons.devices,
          title: "Connected Device",
          subtitle: namaAlat,
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Online",
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () {
            _showDeviceDetails();
          },
        ),
        _buildSettingsItem(
          icon: Icons.fingerprint,
          title: "Device ID",
          subtitle: deviceId,
          onTap: () {
            _copyToClipboard(deviceId, "Device ID copied to clipboard");
          },
        ),
        _buildSettingsItem(
          icon: Icons.wifi,
          title: "Network Settings",
          subtitle: "Configure network connection",
          onTap: () {
            _showNetworkSettings();
          },
        ),
        _buildSettingsItem(
          icon: Icons.update,
          title: "Firmware Update",
          subtitle: "Check for device updates",
          trailing: Text(
            "v$appVersion",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          onTap: () {
            _checkForUpdates();
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSettingsSection(
      title: "Support & About",
      children: [
        _buildSettingsItem(
          icon: Icons.help,
          title: "Help & Support",
          subtitle: "Get help and contact support",
          onTap: () {
            // TODO: Navigate to help
          },
        ),
        _buildSettingsItem(
          icon: Icons.info,
          title: "About",
          subtitle: "App version and information",
          onTap: () {
            // TODO: Show about dialog
          },
        ),
        _buildSettingsItem(
          icon: Icons.logout,
          title: "Logout",
          subtitle: "Sign out of your account",
          titleColor: AppColor.red,
          onTap: () {
            _showLogoutDialog();
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColor.hijau3,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: titleColor ?? AppColor.hijau1,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColor.hijau1,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColor.hijau3,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColor.hijau1,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColor.hijau1,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColor.hijau1,
      ),
    );
  }

  // Navigation and Action Methods
  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(),
      ),
    );

    // If profile was updated, reload user data
    if (result == true) {
      _loadUserData();
    }
  }

  void _showDeviceDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Device Details',
            style: TextStyle(
              color: AppColor.hijau1,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Device Name", namaAlat),
              _buildDetailRow("Device ID", deviceId),
              _buildDetailRow("Status", "Online"),
              _buildDetailRow("Last Sync", "Just now"),
              _buildDetailRow("Firmware", "v$appVersion"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: AppColor.hijau1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColor.hijau1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String message) {
    // TODO: Implement clipboard functionality
    _showSnackBar(message);
  }

  void _showNetworkSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Network Settings',
            style: TextStyle(
              color: AppColor.hijau1,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.wifi, color: AppColor.hijau1),
                title: Text("WiFi Configuration"),
                subtitle: Text("Configure WiFi connection"),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonDialog("WiFi Configuration");
                },
              ),
              ListTile(
                leading: Icon(Icons.network_check, color: AppColor.hijau1),
                title: Text("Network Test"),
                subtitle: Text("Test network connectivity"),
                onTap: () {
                  Navigator.pop(context);
                  _testNetworkConnection();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: AppColor.hijau1),
              ),
            ),
          ],
        );
      },
    );
  }

  void _checkForUpdates() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Firmware Update',
            style: TextStyle(
              color: AppColor.hijau1,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Your device is up to date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Current version: v$appVersion',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: AppColor.hijau1),
              ),
            ),
          ],
        );
      },
    );
  }

  void _testNetworkConnection() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Testing Connection',
            style: TextStyle(
              color: AppColor.hijau1,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.hijau1),
              ),
              SizedBox(height: 16),
              Text('Testing network connectivity...'),
            ],
          ),
        );
      },
    );

    // Simulate network test
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
      _showNetworkTestResult();
    });
  }

  void _showNetworkTestResult() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Network Test Result',
            style: TextStyle(
              color: AppColor.hijau1,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Connection Successful',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your device is connected to the internet',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: AppColor.hijau1),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Coming Soon',
            style: TextStyle(
              color: AppColor.hijau1,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('$feature feature is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: AppColor.hijau1),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.hijau1,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              color: AppColor.hijau1,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      await pref.clear();

      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      _showSnackBar('Error during logout: $e');
    }
  }
}

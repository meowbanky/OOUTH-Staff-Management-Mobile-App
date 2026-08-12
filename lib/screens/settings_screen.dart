import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'forgot_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();

  bool _biometricEnabled = false;
  bool _rememberMe = false;
  bool _pushNotificationsEnabled = false;
  bool _biometricsAvailable = false;
  bool _isLoading = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      _biometricService.getBiometricStatus(),
      _biometricService.isRememberMeEnabled(),
      _biometricService.isBiometricsAvailable(),
      PackageInfo.fromPlatform(),
    ]);

    final pushEnabled = OneSignal.Notifications.permission;

    if (mounted) {
      setState(() {
        _biometricEnabled = results[0] as bool;
        _rememberMe = results[1] as bool;
        _biometricsAvailable = results[2] as bool;
        _appVersion =
            (results[3] as PackageInfo).version;
        _pushNotificationsEnabled = pushEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !_biometricsAvailable) {
      _showInfo('Biometric authentication is not available on this device.');
      return;
    }
    await _biometricService.setBiometricEnabled(value);
    if (!value) {
      // Also turn off remember me if biometrics is disabled
      await _biometricService.setRememberMe(false);
      setState(() => _rememberMe = false);
    }
    setState(() => _biometricEnabled = value);
  }

  Future<void> _toggleRememberMe(bool value) async {
    if (value && !_biometricEnabled) {
      _showInfo('Please enable biometric login first.');
      return;
    }
    await _biometricService.setRememberMe(value);
    if (!mounted) return;
    await context.read<AuthProvider>().setRememberMe(value);
    setState(() => _rememberMe = value);
  }

  Future<void> _togglePushNotifications(bool value) async {
    if (value) {
      await OneSignal.Notifications.requestPermission(true);
      OneSignal.User.pushSubscription.optIn();
    } else {
      OneSignal.User.pushSubscription.optOut();
    }
    setState(() => _pushNotificationsEnabled = value);
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(
              color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://oouthsalary.com.ng/privacy_policy.html';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account card
                _buildAccountCard(user?.name ?? '', user?.email ?? '',
                    user?.id ?? ''),
                const SizedBox(height: 20),

                // Security section
                _buildSectionHeader('Security'),
                _buildSettingsCard([
                  _buildSwitchTile(
                    icon: Icons.fingerprint,
                    iconColor: AppTheme.primaryColor,
                    title: 'Biometric Login',
                    subtitle: _biometricsAvailable
                        ? 'Use fingerprint or face to login'
                        : 'Not available on this device',
                    value: _biometricEnabled && _biometricsAvailable,
                    onChanged:
                        _biometricsAvailable ? _toggleBiometric : null,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSwitchTile(
                    icon: Icons.lock_outline,
                    iconColor: AppTheme.primaryColor,
                    title: 'Remember Me',
                    subtitle: 'Stay logged in between sessions',
                    value: _rememberMe,
                    onChanged: _biometricEnabled ? _toggleRememberMe : null,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildNavTile(
                    icon: Icons.key_outlined,
                    iconColor: Colors.orange,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Notifications section
                _buildSectionHeader('Notifications'),
                _buildSettingsCard([
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.deepOrange,
                    title: 'Push Notifications',
                    subtitle: 'Receive salary and duty alerts',
                    value: _pushNotificationsEnabled,
                    onChanged: _togglePushNotifications,
                  ),
                ]),
                const SizedBox(height: 20),

                // About section
                _buildSectionHeader('About'),
                _buildSettingsCard([
                  _buildInfoTile(
                    icon: Icons.info_outline,
                    iconColor: Colors.blueGrey,
                    title: 'App Version',
                    trailing: Text(
                      'v$_appVersion',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildNavTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.teal,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: _openPrivacyPolicy,
                  ),
                ]),
                const SizedBox(height: 28),

                // Logout button
                OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildAccountCard(String name, String email, String staffId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text('Staff ID: $staffId',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: onChanged == null ? Colors.grey : null)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: trailing,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

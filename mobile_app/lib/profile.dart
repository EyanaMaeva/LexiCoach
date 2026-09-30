import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'notifications_page.dart';
import 'profile_settings_page.dart';
import 'services/auth_module.dart';
import 'signin.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "Loading...";
  String userEmail = "Loading...";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final authApi = AuthApiService();
      final response = await authApi.me();
      final user = response['data']['user'];

      if (!mounted) return;

      setState(() {
        userName = user['full_name'] ?? "User";
        userEmail = user['email'] ?? "";
      });
    } catch (error) {
      debugPrint('Error loading user: $error');

      if (!mounted) return;

      setState(() {
        userName = "User";
        userEmail = "";
      });
    }
  }

  Future<void> logout() async {
    try {
      final authApi = AuthApiService();
      await authApi.logout();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignIn()),
      );
    } catch (error) {
      debugPrint('Logout error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
    );
    if (!mounted) return;
    await loadUser();
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textDark,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textDark,
            ),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage(
                        "assets/images/landing_img.jpeg",
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Lessons", "12"),
                _buildStatItem("Hours", "45"),
                _buildStatItem("Streak", "7"),
              ],
            ),
            const SizedBox(height: 32),
            _buildMenuItem(
              Icons.settings_outlined,
              "Settings",
              onTap: _openSettings,
            ),
            _buildMenuItem(
              Icons.person_outline,
              "Personal Info",
              onTap: _openSettings,
            ),
            _buildMenuItem(
              Icons.notifications_none,
              "Notifications",
              onTap: _openNotifications,
            ),
            _buildMenuItem(
              Icons.lock_outline,
              "Security",
              onTap: _openSettings,
            ),
            _buildMenuItem(Icons.help_outline, "Help Center"),
            const SizedBox(height: 20),
            _buildMenuItem(
              Icons.logout,
              "Log out",
              isDestructive: true,
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Icon(
            icon,
            color: isDestructive ? Colors.red : AppColors.primary,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red : AppColors.textDark,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
          onTap: onTap,
        ),
      ),
    );
  }
}

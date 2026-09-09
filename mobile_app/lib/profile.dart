import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'services/auth_module.dart';
import 'signin.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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

      // Get the currently logged-in user from Laravel
      final response = await authApi.me();

      // Get the user data from the API response
      final user = response['data']['user'];

      if (!mounted) return;

      setState(() {
        userName = user['full_name'] ?? "User";
        userEmail = user['email'] ?? "";
      });
    } catch (error) {
      print('Error loading user: $error');

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
        MaterialPageRoute(
          builder: (context) => const SignIn(),
        ),
      );
    } catch (error) {
      print('Logout error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),

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
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),

        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Image
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
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

            // LOGGED-IN USER NAME
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),

            // LOGGED-IN USER EMAIL
            Text(
              userEmail,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),

            const SizedBox(height: 32),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [
                _buildStatItem("Lessons", "12"),
                _buildStatItem("Hours", "45"),
                _buildStatItem("Streak", "7"),
              ],
            ),

            const SizedBox(height: 32),

            // Menu Items
            _buildMenuItem(
              Icons.person_outline,
              "Personal Info",
            ),

            _buildMenuItem(
              Icons.notifications_none,
              "Notifications",
            ),

            _buildMenuItem(
              Icons.lock_outline,
              "Security",
            ),

            _buildMenuItem(
              Icons.help_outline,
              "Help Center",
            ),

            const SizedBox(height: 20),

            // LOG OUT
            _buildMenuItem(
              Icons.logout,
              "Log Out",
              isDestructive: true,
              onTap: logout,
            ),

            const SizedBox(height: 40),
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

          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: ListTile(
        leading: Icon(
          icon,

          color: isDestructive
              ? Colors.red
              : AppColors.primary,
        ),

        title: Text(
          title,

          style: TextStyle(
            fontWeight: FontWeight.w600,

            color: isDestructive
                ? Colors.red
                : AppColors.textDark,
          ),
        ),

        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textLight,
        ),

        onTap: onTap,
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'ai_conversation_page.dart';
import 'app_colors.dart';
import 'dashboard.dart';
import 'learning_modes_page.dart';
import 'profile.dart';
import 'progress_chart_page.dart';
import 'tutor_link_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.userName = 'User'});

  final String userName;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    Dashboard(
      userName: widget.userName,
      onOpenLearningModes: () => _changePage(2),
      onOpenProgress: () => _changePage(1),
    ),
    const ProgressChartPage(showBackButton: false),
    const LearningModesPage(showBackButton: false),
    const TutorLinkPage(showBackButton: false),
    const ProfilePage(showBackButton: false),
  ];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAiConversation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiConversationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_currentIndex],
      bottomNavigationBar: _ModernBottomNav(
        currentIndex: _currentIndex,
        onChanged: _changePage,
        onCenterTap: _openAiConversation,
      ),
      extendBody: true,
    );
  }
}

class _ModernBottomNav extends StatelessWidget {
  const _ModernBottomNav({
    required this.currentIndex,
    required this.onChanged,
    required this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 74,
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.textFieldBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      onTap: () => onChanged(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Chart',
                      isSelected: currentIndex == 1,
                      onTap: () => onChanged(1),
                    ),
                  ),
                  const SizedBox(width: 76),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.supervisor_account_rounded,
                      label: 'Tutor',
                      isSelected: currentIndex == 3,
                      onTap: () => onChanged(3),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: currentIndex == 4,
                      onTap: () => onChanged(4),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 32,
              child: GestureDetector(
                onTap: onCenterTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 66,
                  width: 66,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 30,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

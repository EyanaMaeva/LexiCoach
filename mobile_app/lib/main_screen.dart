import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'dashboard.dart';
import 'practice_exercises.dart';
import 'profile.dart';
import 'reading_exercises_list.dart';
import 'writing_exercises_list.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.userName = 'User'});

  final String userName;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    Dashboard(userName: widget.userName),
    const PracticeExercises(showBackButton: false),
    const ReadingExercisesList(showBackButton: false),
    const WritingExercisesList(showBackButton: false),
    const ProfilePage(showBackButton: false),
  ];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _changePage,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_rounded),
              label: 'Practice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Reading',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_rounded),
              label: 'Write',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      extendBody: true,
    );
  }
}

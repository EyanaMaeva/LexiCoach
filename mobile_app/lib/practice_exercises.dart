import 'package:flutter/material.dart';
import 'reading_practice.dart';

class PracticeExercises extends StatelessWidget {
  const PracticeExercises({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: const Color(0xFF222033),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Practice Exercises",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF222033),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Choose a category to practice",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF77718A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz_rounded),
                    color: const Color(0xFF222033),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildCategoryCard(
                    context,
                    "Reading",
                    "Improve reading fluency",
                    Icons.menu_book_rounded,
                    const Color(0xFFE8E1FF),
                    const Color(0xFF6547E8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReadingPractice()),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    "Spelling",
                    "Practice difficult words",
                    Icons.abc_rounded,
                    const Color(0xFFFFF3E0),
                    const Color(0xFFFF9800),
                  ),
                  _buildCategoryCard(
                    context,
                    "Vocabulary",
                    "Learn new words",
                    Icons.credit_card_rounded, // Similar to the icon in image
                    const Color(0xFFE0F2F1),
                    const Color(0xFF009688),
                  ),
                  _buildCategoryCard(
                    context,
                    "Comprehension",
                    "Understand what you read",
                    Icons.help_outline_rounded,
                    const Color(0xFFFFEBEE),
                    const Color(0xFFF44336),
                  ),
                  _buildCategoryCard(
                    context,
                    "Listening",
                    "Improve listening skills",
                    Icons.headset_rounded,
                    const Color(0xFFE8EAF6),
                    const Color(0xFF3F51B5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1, // Practice tab selected
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6547E8),
          unselectedItemColor: const Color(0xFFAAA5B7),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'Practice'),
            BottomNavigationBarItem(icon: Icon(Icons.chrome_reader_mode_rounded), label: 'Read'),
            BottomNavigationBarItem(icon: Icon(Icons.edit_note_rounded), label: 'Write'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2DDF2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222033),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF77718A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF222033),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

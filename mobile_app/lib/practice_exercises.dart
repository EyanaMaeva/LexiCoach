import 'package:flutter/material.dart';
import 'reading_practice.dart';
import 'app_colors.dart';

import 'package:lexicoach/reading_exercises_list.dart';

class PracticeExercises extends StatelessWidget {
  const PracticeExercises({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- CUSTOM MODERN HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: Colors.black12,
                    ),
                  ),
                  const Column(
                    children: [
                      Text(
                        "Practice",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        "Drills & Skills",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // Spacer to balance header
                ],
              ),
            ),

            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(24),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
                children: [
                  _buildModernCategoryCard(
                    context,
                    "Reading",
                    "Fluency practice",
                    Icons.menu_book_rounded,
                    const Color(0xFFE8E1FF),
                    AppColors.logoBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReadingExercisesList()),
                      );
                    },
                  ),
                  _buildModernCategoryCard(
                    context,
                    "Vocabulary",
                    "Expand your lexicon",
                    Icons.auto_awesome_motion_rounded,
                    const Color(0xFFE0F2F1),
                    AppColors.logoTeal,
                  ),
                  _buildModernCategoryCard(
                    context,
                    "Spelling",
                    "Master difficult words",
                    Icons.abc_rounded,
                    const Color(0xFFFFF3E0),
                    AppColors.logoOrange,
                  ),

                  _buildModernCategoryCard(
                    context,
                    "Listen",
                    "Aural comprehension",
                    Icons.headset_rounded,
                    const Color(0xFFF3E5F5),
                    Colors.purple,

                  ),
                  _buildModernCategoryCard(
                    context,
                    "Grammar",
                    "Sentence structures",
                    Icons.edit_note_rounded,
                    const Color(0xFFE8EAF6),
                    AppColors.logoPurple,
                  ),
                  _buildModernCategoryCard(
                    context,
                    "Daily Quiz",
                    "Test your knowledge",
                    Icons.timer_outlined,
                    const Color(0xFFFFEBEE),
                    const Color(0xFFF44336),

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.4), // Subtle tint for the card
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2), // Clean white border
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white, // White container for icon to pop
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

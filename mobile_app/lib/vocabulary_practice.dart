import 'package:flutter/material.dart';
import 'app_colors.dart';

class VocabularyPractice extends StatelessWidget {
  const VocabularyPractice({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
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
                    ),
                  ),
                  const Text(
                    "Vocabulary",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildLessonCard("Visual Words", "Learn with images", Icons.image_rounded, AppColors.logoTeal),
                    _buildLessonCard("Synonyms", "Expand your choices", Icons.swap_horiz_rounded, AppColors.logoBlue),
                    _buildLessonCard("Context Clues", "Read between the lines", Icons.find_in_page_rounded, AppColors.logoPurple),
                    _buildLessonCard("Antonyms", "Opposite meanings", Icons.unfold_more_rounded, AppColors.logoOrange),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill_rounded, color: color, size: 32),
        ],
      ),
    );
  }
}

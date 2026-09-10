import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'practice_exercises.dart';
import 'reading_exercises_list.dart';
import 'app_colors.dart';
import 'writing_exercises_list.dart';

class Dashboard extends StatefulWidget {
  final String userName;
  const Dashboard({super.key, this.userName = "User"});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Hello, ${widget.userName}!",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Lottie.asset(
                            "assets/lotties/hand wave.json",
                            width: 40,
                            height: 40,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Ready to learn something new today?",
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Continue Learning Card (Modernized & Interactive)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF9FA8DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Continue Learning",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Reading Practice",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text(
                                            "Lesson 5 - Animals",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white60,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              "70%",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: 85,
                                      width: 85,
                                      child: CircularProgressIndicator(
                                        value: 0.7,
                                        strokeWidth: 10,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image.asset(
                                        "assets/images/landing_img.jpeg",
                                        height: 65,
                                        width: 65,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: 0.7,
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ReadingExercisesList(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "Start Learning",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // Modules Section Header
              const Text(
                "Popular Exercises",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 20),

              // Modules Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildModuleCard(
                    context,
                    "Practice",
                    Icons.psychology_rounded,
                    const Color(0xFFE8E1FF),
                    AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PracticeExercises(),
                        ),
                      );
                    },
                  ),
                  _buildModuleCard(
                    context,
                    "Read",
                    Icons.description_rounded,
                    const Color(0xFFE1F5FE),
                    const Color(0xFF03A9F4),
                  ),
                  _buildModuleCard(
                    context,
                    "Write",
                    Icons.edit_rounded,
                    const Color(0xFFFFF3E0),
                    const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WritingExercisesList(),
                        ),
                      );
                    },
                  ),
                  _buildModuleCard(
                    context,
                    "Search",
                    Icons.search_rounded,
                    const Color(0xFFE0F2F1),
                    const Color(0xFF009688),
                  ),
                ],
              ),
              const SizedBox(height: 100), // Space for the central bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

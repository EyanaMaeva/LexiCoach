import 'package:flutter/material.dart';
import 'signin.dart';
import 'signup.dart';
import 'app_colors.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              // 1. SPLASH PAGE
              _buildSplashPage(),
              
              // 2. FEATURE: SMART READING
              _buildFeaturePage(
                title: "Smart Reading Practice",
                description: "Interactive tools designed to adapt to your specific reading style, helping you learn with confidence.",
                imagePath: "assets/images/landing_img.jpeg",
                bgColor: const Color(0xFFF9F9FF),
              ),

              // 3. FEATURE: WRITING CONFIDENCE
              _buildFeaturePage(
                title: "Write with Confidence",
                description: "Unlock powerful writing assistants that help you structure ideas and express yourself clearly.",
                imagePath: "assets/images/landing_img.jpeg",
                bgColor: Colors.white,
              ),

              // 4. FEATURE: PROGRESS TRACKING
              _buildFeaturePage(
                title: "Track Your Growth",
                description: "Celebrate every milestone with personalized insights and visual progress indicators.",
                imagePath: "assets/images/landing_img.jpeg",
                bgColor: const Color(0xFFF0F2FF),
              ),
            ],
          ),

          // SKIP BUTTON (Top Right)
          if (_currentPage < _numPages - 1)
            Positioned(
              top: 60,
              right: 24,
              child: TextButton(
                onPressed: () {
                  _pageController.jumpToPage(_numPages - 1);
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // PERSISTENT BOTTOM CONTROLS
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_numPages, (index) => _buildDot(index)),
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _numPages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpPage()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _numPages - 1 ? "Get Started" : "Continue",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignIn()),
                    );
                  },
                  child: const Text(
                    "Already have an account? Log In",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primary : const Color(0xFFD8D8D8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSplashPage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 4),
          Hero(
            tag: 'logo',
            child: Image.asset("assets/images/logo.png", width: 300),
          ),
          const SizedBox(height: 32),
          const Text(
            "Empowering Every Learner",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(flex: 2),
          const Text(
            "Swipe to discover our features",
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildFeaturePage({
    required String title,
    required String description,
    required String imagePath,
    required Color bgColor,
  }) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                imagePath,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.textLight,
              height: 1.6,
            ),
          ),
          const Spacer(flex: 3),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

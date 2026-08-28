import 'package:flutter/material.dart';

class ReadingPractice extends StatelessWidget {
  const ReadingPractice({super.key});

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
                    child: Center(
                      child: Text(
                        "Reading Practice",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF222033),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    "3 / 10",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF77718A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz_rounded),
                    color: const Color(0xFF222033),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0.3,
                  minHeight: 6,
                  backgroundColor: Color(0xFFE2DDF2),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6547E8)),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Read the sentence aloud:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222033),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Sentence Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2DDF2), width: 1),
                      ),
                      child: RichText(
                        textAlign: TextAlign.left,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 26,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222033),
                          ),
                          children: [
                            TextSpan(text: "The children visited the "),
                            TextSpan(
                              text: "beautiful",
                              style: TextStyle(color: Color(0xFF6547E8)),
                            ),
                            TextSpan(text: " museum yesterday."),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Listen Button
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.volume_up_rounded, size: 20),
                        label: const Text("Listen"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6547E8),
                          side: const BorderSide(color: Color(0xFFE2DDF2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Microphone Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6547E8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6547E8).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Tap the microphone to start",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF77718A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
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
}

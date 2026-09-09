import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors from Logo
  static const Color logoTeal = Color(0xFF1DE9B6);   // Cyan/Teal (Top)
  static const Color logoBlue = Color(0xFF448AFF);   // Deep Blue (Body)
  static const Color logoPurple = Color(0xFF7C4DFF); // Purple (Bottom)
  static const Color logoOrange = Color(0xFFFF9100); // Vibrant Orange (Dot)
  static const Color logoNavy = Color(0xFF1A237E);   // Deep Navy (Text)

  // Functional Palette
  static const Color primary = logoBlue;
  static const Color secondary = logoTeal;
  static const Color accent = logoOrange;
  static const Color background = Color(0xFFF8FAFF); // Clean bluish background
  
  static const Color textDark = logoNavy;
  static const Color textLight = Color(0xFF707E94); // Slate Gray
  
  static const Color textFieldBorder = Color(0xFFE0E7FF);
  static const Color textFieldFill = Colors.white;
  static const Color socialButtonBorder = Color(0xFFE0E7FF);
  
  static const Color cardBg = Colors.white;
  
  // Gradients
  static const List<Color> logoGradient = [
    logoTeal,
    logoBlue,
    logoPurple,
  ];
}

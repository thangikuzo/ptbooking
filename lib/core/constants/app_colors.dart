import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1D5D9B);
  static const Color primaryDark = Color(0xFF0B2447);
  static const Color primaryLight = Color(0xFFEAF4FF);
  static const Color blueAccent = Color(0xFF4BA3E3);
  static const Color accent = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF102A43);
  static const Color mutedText = Color(0xFF64748B);
  static const Color border = Color(0xFFD8E3F0);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, blueAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

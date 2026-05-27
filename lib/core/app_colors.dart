import 'package:flutter/material.dart';

class AppColors {
  static const Color navyBlue = Color(0xFF0F172A);
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color greenAccent = Color(0xFF22C55E);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color textBody = Color(0xFF94A3B8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [navyBlue, Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

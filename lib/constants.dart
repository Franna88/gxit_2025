import 'package:flutter/material.dart';

class AppColors {
  // Gradient colors inspired by the GXIT logo
  static const Color primaryBlue = Color(0xFF2CB7D8);
  static const Color primaryPurple = Color(0xFF8557C7);
  static const Color primaryOrange = Color(0xFFFF9A5C);
  static const Color primaryGreen = Color(0xFF4CD964);
  static const Color primaryYellow = Color(0xFFFFD24A);

  // Status colors
  static const Color onlineGreen = Color(0xFF4CD964);
  static const Color awayYellow = Color(0xFFFFD24A);
  static const Color offlineRed = Color(0xFFFF5A59);

  // Background and text colors
  static const Color darkBackground = Color(0xFF1E2834);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF2B3A4A);
  static const Color lightText = Color(0xFFE8F0F9);

  // Glass effect colors
  static const Color glassLight = Color(0x40FFFFFF);
  static const Color glassDark = Color(0x30000000);
}

class GradientPalette {
  static const LinearGradient gxitGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryBlue,
      AppColors.primaryPurple,
      AppColors.primaryOrange,
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryPurple, AppColors.primaryOrange],
  );
}

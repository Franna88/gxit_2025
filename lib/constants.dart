import 'package:flutter/material.dart';

class AppColors {
  // Gradient colors inspired by the GXIT logo but more subdued
  static const Color primaryBlue = Color(0xFF1A91C1);
  static const Color primaryPurple = Color(0xFF6247A0);
  static const Color primaryOrange = Color(0xFFD27D46);
  static const Color primaryGreen = Color(0xFF3DA455);
  static const Color primaryYellow = Color(0xFFD9B044);

  // Status colors
  static const Color onlineGreen = Color(0xFF3DA455);
  static const Color awayYellow = Color(0xFFD9B044);
  static const Color offlineRed = Color(0xFFD35050);

  // Background and text colors - darker theme
  static const Color darkBackground = Color(0xFF121A24);
  static const Color darkSecondaryBackground = Color(0xFF1A2330);
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color darkText = Color(0xFF1A2330);
  static const Color lightText = Color(0xFFE2E7F0);
  static const Color subtleText = Color(0xFF8E95A5);

  // Glass effect colors
  static const Color glassLight = Color(0x40FFFFFF);
  static const Color glassDark = Color(0x15FFFFFF);
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
    colors: [AppColors.primaryBlue, AppColors.primaryPurple],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.darkBackground, Color(0xFF0B1117)],
  );
}

import 'package:flutter/material.dart';

class AppColors {
  // Main Theme Colors
  static const Color primaryIndigo = Color(0xFF5534D2); // Main primary color
  static const Color lightLavender = Color(0xFFE6E1FF); // Light purple
  static const Color mediumIndigo = Color(0xFF8B6EF3); // Mid-level indigo
  static const Color darkIndigo = Color(0xFF4029A8); // Darker indigo
  static const Color backgroundLavender = Color(0xFFEAE6FF); // Soft background

  // Accent Colors
  static const Color accentViolet = Color(0xFFAA7FF7); // Accent purple
  static const Color accentRed = Color(
    0xFFF76B8A,
  ); // Accent red (delete, error buttons)
  static const Color iconPurple = Color(0xFF7E55F2); // Purple for icons

  // Status Colors
  static const Color successGreen = Color(0xFF34D399); // Green success
  static const Color successLightGreen = Color(
    0xFFD1FAE5,
  ); // Light green background
  static const Color errorRed = Color(0xFFF43F5E); // Error red
  static const Color errorLightRed = Color(
    0xFFFECAD3,
  ); // Light error background

  // Text Colors
  static const Color textDark = Color(0xFF1E293B); // Dark text (main)
  static const Color textMedium = Color(0xFF64748B); // Medium gray text
  static const Color textLight = Color(0xFF94A3B8); // Light gray text
  static const Color white = Color(0xFFFFFFFF); // White

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF2A2A2A);
  static const Color darkBorderColor = Color(0xFF3A3A3A);

  // For consistency across files
  static const Color deepPurple = primaryIndigo;
  static const Color lightPurple = lightLavender;
  static const Color lavender = mediumIndigo;
  static const Color backgroundLilac = backgroundLavender;
  static const Color shadowColor = Color(0x1A000000);
  static const Color borderGrey = Color(0xFFE2E8F0);
}

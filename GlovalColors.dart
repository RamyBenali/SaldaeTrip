import 'dart:ui';

import 'package:flutter/material.dart';

class GlobalColors {
  static bool isDarkMode = false;

  // Light mode colors
  static Color lightPrimary = Color(0xFFF9FAFB);
  static Color lightSecondary = Color(0xFF1F2937);
  static Color lightAccent = Color(0xFF6B7280);
  static Color lightCard = Colors.white;

  // Dark mode colors
  static Color darkPrimary = Color(0xFF111827);
  static Color darkSecondary = Colors.white;
  static Color darkAccent = Color(0xFF9CA3AF);
  static Color darkCard = Color(0xFF1F2937);

  // Getters
  static Color get primaryColor => isDarkMode ? darkPrimary : lightPrimary;
  static Color get secondaryColor =>
      isDarkMode ? darkSecondary : lightSecondary;
  static Color get accentColor => isDarkMode ? darkAccent : lightAccent;
  static Color get cardColor => isDarkMode ? darkCard : lightCard;

  // Specific colors that don't change with theme
  static Color get blueColor => Color(0xFF3B82F6);
  static Color get darkBlueColor => Color(0xFF1E40AF);
  static Color get pinkColor => Color(0xFFEC4899);
  static Color get greenColor => Color(0xFF10B981);
  static Color get amberColor => Colors.amber;
  static Color get bleuTurquoise => Color(0xFF41A6B4);

}
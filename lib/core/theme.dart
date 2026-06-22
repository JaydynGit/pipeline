import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color primaryBlue = Color(0xFF3A8DFF);
  static const Color primaryPurple = Color(0xFF8A2BE2);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto', // Modern system default fallback
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryPurple,
      surface: cardColor,
    ),
  );
}

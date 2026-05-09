import 'package:flutter/material.dart';

class CategoryColors {
  final Color primary;
  final Color secondary;
  final Color bg;

  const CategoryColors({
    required this.primary,
    required this.secondary,
    required this.bg,
  });
}

class AppTheme {
  static const Color darkBg = Color(0xFF0d1b1e);
  static const Color lightBg = Color(0xFFf9fafb);
  
  static const Color yellowPrimary = Color(0xFFeab308); // Tailwind yellow-500
  static const Color yellowSecondary = Color(0xFFca8a04); // Tailwind yellow-600
  
  static const Color bluePrimary = Color(0xFF3b82f6); // Tailwind blue-500
  static const Color blueSecondary = Color(0xFF2563eb); // Tailwind blue-600
  
  static const Map<String, CategoryColors> categoryColors = {
    'sports': CategoryColors(
      primary: yellowPrimary,
      secondary: yellowSecondary,
      bg: Color(0x33eab308),
    ),
    'study': CategoryColors(
      primary: bluePrimary,
      secondary: blueSecondary,
      bg: Color(0x333b82f6),
    ),
    'chill': CategoryColors(
      primary: Color(0xFF60a5fa), // blue-400
      secondary: bluePrimary,
      bg: Color(0x333b82f6),
    ),
    'creative': CategoryColors(
      primary: yellowPrimary,
      secondary: yellowSecondary,
      bg: Color(0x33eab308),
    ),
  };

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: yellowPrimary,
      colorScheme: const ColorScheme.light(
        primary: yellowPrimary,
        secondary: bluePrimary,
        surface: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: yellowPrimary,
      colorScheme: const ColorScheme.dark(
        primary: yellowPrimary,
        secondary: bluePrimary,
        surface: Color(0xFF1f2937), // gray-800
      ),
      useMaterial3: true,
    );
  }
}

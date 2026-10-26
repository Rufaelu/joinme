import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// JoinMe palette: violet brand colour with a warm pink accent on deep indigo
/// (dark) or soft lavender (light) backgrounds. Use these instead of hardcoded
/// Material colours so the whole app stays consistent.
class AppTheme {
  // Brand
  static const Color primaryLight = Color(0xFFA594FF);
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryDark = Color(0xFF5B3FE0);

  static const Color accentLight = Color(0xFFFF8FB0);
  static const Color accent = Color(0xFFFF5C8A);
  static const Color accentDark = Color(0xFFE03E6E);

  // Backgrounds (screens use a top → bottom gradient of these)
  static const Color darkBg = Color(0xFF0E0D1A);
  static const Color darkBg2 = Color(0xFF1C1A33);
  static const Color lightBg = Color(0xFFF8F7FC);
  static const Color lightBg2 = Color(0xFFECEAF6);

  /// Avatar / highlight gradient.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static CategoryColors colorsFor(String? category) =>
      categoryColors[category] ?? categoryColors['creative']!;

  static const Map<String, CategoryColors> categoryColors = {
    'sports': CategoryColors(
      primary: Color(0xFF22C55E), // green
      secondary: Color(0xFF15803D),
      bg: Color(0x3322C55E),
    ),
    'study': CategoryColors(
      primary: Color(0xFF3B82F6), // blue
      secondary: Color(0xFF1D4ED8),
      bg: Color(0x333B82F6),
    ),
    'chill': CategoryColors(
      primary: accent, // pink
      secondary: accentDark,
      bg: Color(0x33FF5C8A),
    ),
    'creative': CategoryColors(
      primary: Color(0xFFA855F7), // purple
      secondary: Color(0xFF7E22CE),
      bg: Color(0x33A855F7),
    ),
  };

  /// Themes as used by the app (with the Inter font). Both text themes are built
  /// from their own ThemeData so light and dark styles share the same "inherit"
  /// setting — otherwise Flutter can't animate between them and throws on toggle.
  static ThemeData light(BuildContext context) {
    final base = lightTheme;
    return base.copyWith(textTheme: GoogleFonts.interTextTheme(base.textTheme));
  }

  static ThemeData dark(BuildContext context) {
    final base = darkTheme;
    return base.copyWith(textTheme: GoogleFonts.interTextTheme(base.textTheme));
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: accent,
        surface: darkBg2,
      ),
      useMaterial3: true,
    );
  }
}

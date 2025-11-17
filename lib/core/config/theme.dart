import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color tertiaryColor = Color(0xFF7D5260);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFBFE);
  static const Color lightSurface = Color(0xFFFFFBFE);
  static const Color lightOnBackground = Color(0xFF1C1B1F);
  static const Color lightOnSurface = Color(0xFF1C1B1F);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1C1B1F);
  static const Color darkSurface = Color(0xFF1C1B1F);
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  static const Color darkOnSurface = Color(0xFFE6E1E5);

  // Sepia Theme Colors
  static const Color sepiaBackground = Color(0xFFF4ECD8);
  static const Color sepiaSurface = Color(0xFFF4ECD8);
  static const Color sepiaOnBackground = Color(0xFF4A4033);
  static const Color sepiaOnSurface = Color(0xFF4A4033);

  // Reading Theme Colors
  static const Map<String, ReadingThemeColors> readingThemes = {
    'light': ReadingThemeColors(
      name: 'Light',
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF1A1A1A),
      accent: Color(0xFF6750A4),
    ),
    'dark': ReadingThemeColors(
      name: 'Dark',
      background: Color(0xFF1A1A1A),
      onBackground: Color(0xFFE8E8E8),
      accent: Color(0xFF8B7FD9),
    ),
    'sepia': ReadingThemeColors(
      name: 'Sepia',
      background: Color(0xFFF4ECD8),
      onBackground: Color(0xFF4A4033),
      accent: Color(0xFF8B6914),
    ),
    'night': ReadingThemeColors(
      name: 'Night',
      background: Color(0xFF0D1117),
      onBackground: Color(0xFFC9D1D9),
      accent: Color(0xFF58A6FF),
    ),
    'paper': ReadingThemeColors(
      name: 'Paper',
      background: Color(0xFFFFFDF7),
      onBackground: Color(0xFF2C2C2C),
      accent: Color(0xFF8B6914),
    ),
    'forest': ReadingThemeColors(
      name: 'Forest',
      background: Color(0xFFE8F5E9),
      onBackground: Color(0xFF1B5E20),
      accent: Color(0xFF388E3C),
    ),
    'ocean': ReadingThemeColors(
      name: 'Ocean',
      background: Color(0xFFE3F2FD),
      onBackground: Color(0xFF0D47A1),
      accent: Color(0xFF1976D2),
    ),
  };

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: lightSurface,
        onSurface: lightOnSurface,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightBackground,
        foregroundColor: lightOnBackground,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: darkSurface,
        onSurface: darkOnSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkBackground,
        foregroundColor: darkOnBackground,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class ReadingThemeColors {
  final String name;
  final Color background;
  final Color onBackground;
  final Color accent;

  const ReadingThemeColors({
    required this.name,
    required this.background,
    required this.onBackground,
    required this.accent,
  });
}

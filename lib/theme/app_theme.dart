import 'package:flutter/material.dart';

/// PAK Cyber Team brand colors — same as the website.
class PctColors {
  static const Color background = Color(0xFF080706);
  static const Color panel = Color(0xFF14110B);
  static const Color panelBorder = Color(0xFF2A2416);
  static const Color text = Color(0xFFF3EEE3);
  static const Color muted = Color(0xFF9C9484);
  static const Color gold = Color(0xFFD8B25A);
  static const Color goldDark = Color(0xFFB8943A);
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF3FB950);
}

class PctTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PctColors.background,
      primaryColor: PctColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: PctColors.gold,
        secondary: PctColors.gold,
        surface: PctColors.panel,
        error: PctColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PctColors.background,
        foregroundColor: PctColors.text,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PctColors.panel,
        selectedItemColor: PctColors.gold,
        unselectedItemColor: PctColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PctColors.gold,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PctColors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PctColors.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PctColors.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PctColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PctColors.danger),
        ),
        labelStyle: const TextStyle(color: PctColors.muted),
        hintStyle: const TextStyle(color: PctColors.muted),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: PctColors.text),
        bodyLarge: TextStyle(color: PctColors.text),
        titleLarge: TextStyle(color: PctColors.text, fontWeight: FontWeight.w700),
      ),
    );
  }
}

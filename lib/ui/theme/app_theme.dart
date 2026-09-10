import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color accentBlue = Color(0xFF2979FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color warningOrange = Color(0xFFFF9100);
  static const Color dangerRed = Color(0xFFFF1744);

  // Dark Palette
  static const Color darkBackground = Color(0xFF0F141C);
  static const Color darkSurface = Color(0xFF192231);
  static const Color darkSurfaceVariant = Color(0xFF243044);
  static const Color darkCard = Color(0xFF1E283A);

  // AMOLED Palette
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0D0D0D);
  static const Color amoledCard = Color(0xFF141414);

  static ThemeData darkTheme({bool isAmoled = false}) {
    final bg = isAmoled ? amoledBackground : darkBackground;
    final surface = isAmoled ? amoledSurface : darkSurface;
    final card = isAmoled ? amoledCard : darkCard;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentBlue,
        tertiary: neonGreen,
        surface: surface,
        error: dangerRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isAmoled ? Colors.white10 : Colors.white.withAlpha(15),
            width: 1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryCyan,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F8FB),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00838F),
        secondary: Color(0xFF1976D2),
        tertiary: Color(0xFF2E7D32),
        surface: Colors.white,
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1C1E),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1C1E),
        ),
      ),
    );
  }
}

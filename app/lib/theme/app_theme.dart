import 'package:flutter/material.dart';

/// Farben aus docs/BRAND_SETUP.md
class BrandColors {
  static const deepNavy = Color(0xFF081120); // Hintergrund
  static const graphite = Color(0xFF121827); // Karten, Flächen
  static const neonCyan = Color(0xFF21D7FF); // aktive/technische Elemente
  static const neonViolet = Color(0xFFA855F7); // sekundäre Akzente
  static const coralPink = Color(0xFFFF6B7A); // wichtige Aktionen, Status
  static const warmWhite = Color(0xFFF5F1EB); // Überschriften, heller Text

  // Status eines Bandes — überall dieselben Farben (Liste, Detail, Statistik)
  static const read = neonCyan;
  static const duplicate = coralPink;
  static const wishlist = neonViolet;
}

class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme(
        brightness: Brightness.dark,
        primary: BrandColors.neonCyan,
        onPrimary: BrandColors.deepNavy,
        secondary: BrandColors.neonViolet,
        onSecondary: BrandColors.warmWhite,
        tertiary: BrandColors.coralPink,
        onTertiary: BrandColors.deepNavy,
        error: Color(0xFFFF4D5E),
        onError: BrandColors.deepNavy,
        surface: BrandColors.deepNavy,
        onSurface: BrandColors.warmWhite,
        surfaceContainerLow: BrandColors.graphite,
        surfaceContainer: BrandColors.graphite,
        surfaceContainerHigh: Color(0xFF1A2235),
        outline: Color(0xFF2A3348));

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: BrandColors.deepNavy,
      cardTheme: CardThemeData(
        color: BrandColors.graphite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1F2738)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandColors.deepNavy,
        foregroundColor: BrandColors.warmWhite,
        elevation: 0,
      ),
    );
  }
}

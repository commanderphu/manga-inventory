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
  // Rückmeldungen und Hilfsfarben
  static const success = neonCyan;
  static const warning = coralPink;
  static const danger =
      Color(0xFFFF4D5E); // Löschen, Fehler — bewusst nicht Coral
  static const muted = Color(0xFF8A93A6); // Nebentext
  static const surfaceHigh = Color(0xFF1A2235); // Platzhalter, erhöhte Flächen
}

/// Schriften aus docs/BRAND_SETUP.md, gebündelt in assets/fonts/
class BrandFonts {
  static const body = 'Inter';
  static const display = 'SpaceGrotesk';
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
        error: BrandColors.danger,
        onError: BrandColors.deepNavy,
        surface: BrandColors.deepNavy,
        onSurface: BrandColors.warmWhite,
        onSurfaceVariant: BrandColors.muted,
        surfaceContainerLow: BrandColors.graphite,
        surfaceContainer: BrandColors.graphite,
        surfaceContainerHigh: BrandColors.surfaceHigh,
        outline: BrandColors.muted);

    return ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        textTheme: _textTheme,
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
        snackBarTheme: const SnackBarThemeData(
          contentTextStyle: TextStyle(
              fontFamily: BrandFonts.body, color: BrandColors.deepNavy),
          actionTextColor: BrandColors.deepNavy,
        ));
  }

  // Inter für alles, Space Grotesk für Überschriften und AppBar-Titel.
  // Nicht über ThemeData.fontFamily: das würde Space Grotesk wieder
  // mit Inter überschreiben.
  static TextTheme get _textTheme {
    final base = Typography.material2021()
        .white
        .apply(fontFamily: BrandFonts.body);
    TextStyle? display(TextStyle? s) =>
        s?.copyWith(fontFamily: BrandFonts.display);
    return base.copyWith(
      displayLarge: display(base.displayLarge),
      displayMedium: display(base.displayMedium),
      displaySmall: display(base.displaySmall),
      headlineLarge: display(base.headlineLarge),
      headlineMedium: display(base.headlineMedium),
      headlineSmall: display(base.headlineSmall),
      titleLarge: display(base.titleLarge),
    );
  }
}

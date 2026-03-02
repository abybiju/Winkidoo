import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Midnight Romance (dark) + Blush & Wink (light) for Winkidoo.
/// Phase 1 design system: brand and surface tokens are final authority.
class AppTheme {
  // ─────────────────────────────────────────────────────────────────────────
  // DESIGN SYSTEM — Final authority
  // ─────────────────────────────────────────────────────────────────────────

  /// Core brand
  static const Color primaryPink = Color(0xFFE85D93);
  static const Color plum = Color(0xFF6D2E8C);
  static const Color premiumGold = Color(0xFFF5C76B);

  /// Background gradient (midnight plum)
  static const Color bgTop = Color(0xFF0F172A);
  static const Color bgBottom = Color(0xFF1B1030);

  /// Surface elevation: 1 = base cards, 2 = elevated, 3 = highlight
  static const Color surface1 = Color(0xFF2A0F1F);
  static const Color surface2 = Color(0xFF341226);
  static const Color surface3 = Color(0xFF3E1630);

  /// Light-mode pastel expansion for mockup-driven UI.
  static const Color lightSunTop = Color(0xFFFFF7A6);
  static const Color lightSunBottom = Color(0xFFFFFDF6);
  static const Color lightTopBar = Color(0xFFFDF58E);
  static const Color lightCardA = Color(0xFFFFF5DF);
  static const Color lightCardB = Color(0xFFEFE6FF);
  static const Color lightPillBg = Color(0xFFFFE95A);
  static const Color lightPillBorder = Color(0xFFF0CC45);
  static const Color lightNavBg = Color(0xFFFDF9FF);
  static const Color lightBadgeBg = Color(0xFFE85088);

  static const Color darkCardA = Color(0xFF372039);
  static const Color darkCardB = Color(0xFF23172F);

  /// Standard glows
  static BoxShadow get pinkGlow => BoxShadow(
        color: primaryPink.withValues(alpha: 0.35),
        blurRadius: 20,
        spreadRadius: 2,
      );
  static BoxShadow get goldGlow => BoxShadow(
        color: premiumGold.withValues(alpha: 0.4),
        blurRadius: 22,
        spreadRadius: 2,
      );

  static List<BoxShadow> toyCardShadow(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x28B99CCB),
        blurRadius: 26,
        spreadRadius: 1,
        offset: Offset(0, 10),
      ),
      BoxShadow(
        color: Color(0x22FFF4A5),
        blurRadius: 12,
        spreadRadius: 1,
        offset: Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> toyPillShadow(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x2EFFCF53),
        blurRadius: 12,
        spreadRadius: 1,
        offset: Offset(0, 4),
      ),
    ];
  }

  // Legacy / theme mapping
  static const Color primary = primaryPink;
  static const Color secondary = plum;
  static const Color accent = premiumGold;
  static const Color error = Color(0xFFE57373);

  static const Color backgroundStart = bgTop;
  static const Color backgroundEnd = bgBottom;
  static const Color surface = surface1;
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFFFB8D0);

  static const Color lightBackgroundStart = lightSunTop;
  static const Color lightBackgroundEnd = lightSunBottom;
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF3D1A28);
  static const Color lightTextSecondary = Color(0xFF74556A);

  static Color topBarBg(Brightness brightness) =>
      brightness == Brightness.dark ? surface2 : lightTopBar;
  static Color cardGradientA(Brightness brightness) =>
      brightness == Brightness.dark ? darkCardA : lightCardA;
  static Color cardGradientB(Brightness brightness) =>
      brightness == Brightness.dark ? darkCardB : lightCardB;
  static Color pillBg(Brightness brightness) =>
      brightness == Brightness.dark ? premiumGold : lightPillBg;
  static Color pillBorder(Brightness brightness) =>
      brightness == Brightness.dark
          ? plum.withValues(alpha: 0.5)
          : lightPillBorder;
  static Color navBg(Brightness brightness) =>
      brightness == Brightness.dark ? surface2 : lightNavBg;
  static Color navActive(Brightness brightness) =>
      brightness == Brightness.dark ? premiumGold : const Color(0xFF8C5D00);
  static Color navInactive(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondary : const Color(0xFF8A7A9B);
  static Color navTextStrong(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF311300)
          : const Color(0xFF5C3800);
  static Color badgeBg(Brightness brightness) =>
      brightness == Brightness.dark ? primaryPink : lightBadgeBg;

  static List<Color> gradientColors(Brightness brightness) {
    return brightness == Brightness.dark
        ? [backgroundStart, backgroundEnd]
        : [lightBackgroundStart, lightBackgroundEnd];
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundStart,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackgroundStart,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: lightTextSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightTextSecondary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

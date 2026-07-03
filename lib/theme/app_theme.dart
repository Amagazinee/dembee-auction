import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Figma theme.css → Flutter Material 3
class AppTheme {
  AppTheme._();

  // Design tokens (Figma :root)
  static const Color background = Color(0xFF0C0C0E);
  static const Color foreground = Color(0xFFF0EAD8);
  static const Color card = Color(0xFF141418);
  static const Color cardForeground = Color(0xFFF0EAD8);
  static const Color popover = Color(0xFF1A1A1F);
  static const Color primary = Color(0xFFC9A84C);
  static const Color primaryForeground = Color(0xFF0C0C0E);
  static const Color secondary = Color(0xFF1E1E26);
  static const Color secondaryForeground = Color(0xFFC4BBA8);
  static const Color muted = Color(0xFF1A1A20);
  static const Color mutedForeground = Color(0xFF7A7468);
  static const Color destructive = Color(0xFFE03E3E);
  static const Color inputBackground = Color(0xFF1E1E26);
  static const Color border = Color(0x14FFFFFF);

  static const double radius = 4;

  // Хуучин нэр — backward compatible
  static const Color gold = primary;
  static const Color goldLight = Color(0xFFE8C547);
  static const Color darkBackground = background;
  static const Color darkSurface = secondary;
  static const Color darkCard = card;

  static TextStyle get headingStyle =>
      GoogleFonts.fraunces(color: foreground, fontWeight: FontWeight.w600);

  static TextStyle get bodyStyle =>
      GoogleFonts.manrope(color: foreground);

  static TextStyle get monoStyle =>
      GoogleFonts.jetBrainsMono(color: primary);

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        surface: secondary,
        onSurface: foreground,
        error: destructive,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.manrope(color: mutedForeground),
        hintStyle: GoogleFonts.manrope(color: mutedForeground),
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: foreground, displayColor: foreground),
    );

    return base;
  }
}

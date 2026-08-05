import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Portrait Submit design tokens — ДЭМБЭЭ-ээс тусдаа.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFFEFF3F2);
  static const Color backgroundDeep = Color(0xFFDDE6E4);
  static const Color foreground = Color(0xFF14201E);
  static const Color muted = Color(0xFF5C6B68);
  static const Color accent = Color(0xFF0F6B5C);
  static const Color accentSoft = Color(0xFF1A8F7A);
  static const Color surface = Color(0xFFF8FBFA);
  static const Color border = Color(0xFFC5D2CE);
  static const Color danger = Color(0xFFB42318);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accentSoft,
        surface: surface,
        onSurface: foreground,
        error: danger,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: foreground,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: GoogleFonts.outfit(color: muted),
        hintStyle: GoogleFonts.outfit(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

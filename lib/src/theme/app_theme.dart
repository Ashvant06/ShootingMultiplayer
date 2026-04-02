import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF0C0913);
  static const Color night = Color(0xFF171129);
  static const Color panel = Color(0xCC16111F);
  static const Color cyan = Color(0xFF7DEBD8);
  static const Color amber = Color(0xFFF3C56A);
  static const Color rose = Color(0xFFE36A74);
  static const Color mist = Color(0xFFF2E7D5);
  static const Color violet = Color(0xFF8E74E8);
  static const Color emerald = Color(0xFF56C58D);

  static ThemeData build() {
    final baseBody = GoogleFonts.spectralTextTheme();
    final titleText = GoogleFonts.cinzelTextTheme(baseBody);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      textTheme: titleText.copyWith(
        bodyLarge: baseBody.bodyLarge?.copyWith(color: mist),
        bodyMedium: baseBody.bodyMedium?.copyWith(
          color: mist.withValues(alpha: 0.88),
        ),
        bodySmall: baseBody.bodySmall?.copyWith(
          color: mist.withValues(alpha: 0.72),
        ),
        titleMedium: titleText.titleMedium?.copyWith(
          color: mist,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: amber,
        secondary: cyan,
        surface: night,
        error: rose,
        onPrimary: ink,
        onSecondary: ink,
        onSurface: mist,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: ink,
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: mist,
          textStyle: GoogleFonts.spectral(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(color: mist.withValues(alpha: 0.18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF20192B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.spectral(
          color: mist.withValues(alpha: 0.45),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.spectral(
          color: mist.withValues(alpha: 0.78),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: amber.withValues(alpha: 0.16)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: amber, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF211628),
        contentTextStyle: GoogleFonts.spectral(
          color: mist,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

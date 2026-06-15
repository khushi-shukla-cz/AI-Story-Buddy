import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme configuration for a playful, premium,
/// "Peblo + Duolingo" hybrid look and feel.
class AppTheme {
  AppTheme._();

  // Brand palette --------------------------------------------------------
  static const Color primary = Color(0xFF6C5CE7); // playful purple
  static const Color primaryDark = Color(0xFF4834D4);
  static const Color secondary = Color(0xFF00CEC9); // bright teal
  static const Color accentYellow = Color(0xFFFFC93C);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentRed = Color(0xFFFF6B6B);
  static const Color background = Color(0xFFF6F4FF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D2D44);
  static const Color textMuted = Color(0xFF8B8BA7);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE9E4FF), Color(0xFFF6F4FF), Color(0xFFE0FBFB)],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E7CFF), primary],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF55EFC4), accentGreen],
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: primary.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: cardWhite,
      ),
      textTheme: GoogleFonts.baloo2TextTheme().copyWith(
        bodyMedium: GoogleFonts.nunito(
          fontSize: 16,
          color: textDark,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 18,
          color: textDark,
          height: 1.45,
        ),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

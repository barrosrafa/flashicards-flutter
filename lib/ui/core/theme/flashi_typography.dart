import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'flashi_color_tokens.dart';

/// Typography scale pairing Space Grotesk (Display), Plus Jakarta Sans (UI/Body),
/// and JetBrains Mono (FSRS intervals, USN, and code).
class FlashiTypography {
  const FlashiTypography._();

  static TextTheme buildTextTheme(FlashiColorTokens tokens) {
    final TextTheme base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 34,
        height: 40 / 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: tokens.textPrimary,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: tokens.textPrimary,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: tokens.textPrimary,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: tokens.textSecondary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 18 / 14,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: tokens.textSecondary,
      ),
    );
  }

  static TextStyle monoMetric({
    required Color color,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}

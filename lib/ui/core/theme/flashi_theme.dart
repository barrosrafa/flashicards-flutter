import 'package:flutter/material.dart';

import 'flashi_color_tokens.dart';
import 'flashi_typography.dart';

/// Builds Dark OLED ("Spatial Aurora") and Light ("Alabaster Daylight") `ThemeData`.
class FlashiTheme {
  const FlashiTheme._();

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        tokens: FlashiColorTokens.dark,
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        tokens: FlashiColorTokens.light,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required FlashiColorTokens tokens,
  }) {
    final TextTheme textTheme = FlashiTypography.buildTextTheme(tokens);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.bgCanvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: tokens.accentCyan,
        onPrimary: const Color(0xFF05070E),
        secondary: tokens.accentViolet,
        onSecondary: Colors.white,
        error: tokens.ratingAgain,
        onError: Colors.white,
        surface: tokens.bgElevated,
        onSurface: tokens.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: tokens.textPrimary,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceGlassPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: tokens.borderSpecular),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceGlassPrimary,
        hintStyle: TextStyle(color: tokens.textMuted),
        labelStyle: TextStyle(color: tokens.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.borderSpecular),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.borderSpecular),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.accentCyan, width: 1.5),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}

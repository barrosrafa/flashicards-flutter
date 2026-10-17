import 'package:flutter/material.dart';

/// Spatial Aurora ("Cyber-Glass") 3-layer design tokens for Flashi.
///
/// Mirrors the color palette specified in Section 2.1 of `FLASHI_FLUTTER_SDD.md`:
/// - Primary Dark OLED: `#05070E` (Deep Obsidian Void) + `#0B1021` (Cosmic Slate)
/// - Secondary Light: `#F8FAFC` (Alabaster Daylight) + `#FFFFFF`
/// - Electric Cyan (`#00F2FE`) + Neural Violet (`#8B5CF6`)
/// - Semantic FSRS-6 rating colors: Crimson (`#FF3B5C`), Amber (`#FFB800`),
///   Mint (`#00E676`), Cyan (`#00E5FF`).
@immutable
class FlashiColorTokens extends ThemeExtension<FlashiColorTokens> {
  const FlashiColorTokens({
    required this.bgCanvas,
    required this.bgElevated,
    required this.surfaceGlassPrimary,
    required this.surfaceGlassHover,
    required this.borderSpecular,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentCyan,
    required this.accentViolet,
    required this.ratingAgain,
    required this.ratingHard,
    required this.ratingGood,
    required this.ratingEasy,
  });

  final Color bgCanvas;
  final Color bgElevated;
  final Color surfaceGlassPrimary;
  final Color surfaceGlassHover;
  final Color borderSpecular;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentCyan;
  final Color accentViolet;
  final Color ratingAgain;
  final Color ratingHard;
  final Color ratingGood;
  final Color ratingEasy;

  static const FlashiColorTokens dark = FlashiColorTokens(
    bgCanvas: Color(0xFF05070E),
    bgElevated: Color(0xFF0B1021),
    surfaceGlassPrimary: Color(0xBF0F172A),
    surfaceGlassHover: Color(0xD91E293B),
    borderSpecular: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    accentCyan: Color(0xFF00F2FE),
    accentViolet: Color(0xFF8B5CF6),
    ratingAgain: Color(0xFFFF3B5C),
    ratingHard: Color(0xFFFFB800),
    ratingGood: Color(0xFF00E676),
    ratingEasy: Color(0xFF00E5FF),
  );

  static const FlashiColorTokens light = FlashiColorTokens(
    bgCanvas: Color(0xFFF8FAFC),
    bgElevated: Color(0xFFFFFFFF),
    surfaceGlassPrimary: Color(0xD9FFFFFF),
    surfaceGlassHover: Color(0xFFF1F5F9),
    borderSpecular: Color(0x140F172A),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    accentCyan: Color(0xFF0284C7),
    accentViolet: Color(0xFF7C3AED),
    ratingAgain: Color(0xFFE11D48),
    ratingHard: Color(0xFFD97706),
    ratingGood: Color(0xFF059669),
    ratingEasy: Color(0xFF0284C7),
  );

  LinearGradient get primaryAuroraGradient => LinearGradient(
        colors: <Color>[accentCyan, accentViolet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  FlashiColorTokens copyWith({
    Color? bgCanvas,
    Color? bgElevated,
    Color? surfaceGlassPrimary,
    Color? surfaceGlassHover,
    Color? borderSpecular,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accentCyan,
    Color? accentViolet,
    Color? ratingAgain,
    Color? ratingHard,
    Color? ratingGood,
    Color? ratingEasy,
  }) {
    return FlashiColorTokens(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgElevated: bgElevated ?? this.bgElevated,
      surfaceGlassPrimary: surfaceGlassPrimary ?? this.surfaceGlassPrimary,
      surfaceGlassHover: surfaceGlassHover ?? this.surfaceGlassHover,
      borderSpecular: borderSpecular ?? this.borderSpecular,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accentCyan: accentCyan ?? this.accentCyan,
      accentViolet: accentViolet ?? this.accentViolet,
      ratingAgain: ratingAgain ?? this.ratingAgain,
      ratingHard: ratingHard ?? this.ratingHard,
      ratingGood: ratingGood ?? this.ratingGood,
      ratingEasy: ratingEasy ?? this.ratingEasy,
    );
  }

  @override
  FlashiColorTokens lerp(ThemeExtension<FlashiColorTokens>? other, double t) {
    if (other is! FlashiColorTokens) {
      return this;
    }
    return FlashiColorTokens(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      surfaceGlassPrimary:
          Color.lerp(surfaceGlassPrimary, other.surfaceGlassPrimary, t)!,
      surfaceGlassHover:
          Color.lerp(surfaceGlassHover, other.surfaceGlassHover, t)!,
      borderSpecular: Color.lerp(borderSpecular, other.borderSpecular, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      accentViolet: Color.lerp(accentViolet, other.accentViolet, t)!,
      ratingAgain: Color.lerp(ratingAgain, other.ratingAgain, t)!,
      ratingHard: Color.lerp(ratingHard, other.ratingHard, t)!,
      ratingGood: Color.lerp(ratingGood, other.ratingGood, t)!,
      ratingEasy: Color.lerp(ratingEasy, other.ratingEasy, t)!,
    );
  }
}

extension FlashiThemeContextExtension on BuildContext {
  FlashiColorTokens get flashiColors =>
      Theme.of(this).extension<FlashiColorTokens>() ?? FlashiColorTokens.dark;
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/flashi_color_tokens.dart';

/// Translucent glassmorphic Bento card with a 1px specular border, optional
/// accent glow, and smooth tap feedback.
class GlassBentoCard extends StatelessWidget {
  const GlassBentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.accentBorderColor,
    this.onTap,
    this.enableBlur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? accentBorderColor;
  final VoidCallback? onTap;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    Widget container = Container(
      decoration: BoxDecoration(
        color: colors.surfaceGlassPrimary,
        borderRadius: radius,
        border: Border.all(
          color: accentBorderColor ?? colors.borderSpecular,
          width: accentBorderColor != null ? 1.4 : 1.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (accentBorderColor ?? Colors.black).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (enableBlur) {
      container = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: container,
        ),
      );
    }

    return container;
  }
}

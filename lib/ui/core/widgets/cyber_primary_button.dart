import 'package:flutter/material.dart';

import '../../../core/utils/haptics_helper.dart';
import '../theme/flashi_color_tokens.dart';

/// Futuristic Cyber-Glass primary CTA button with Electric Cyan -> Neural Violet
/// gradient, subtle neon glow, and haptic feedback.
class CyberPrimaryButton extends StatelessWidget {
  const CyberPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final bool enabled = onPressed != null && !isLoading;

    final Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      decoration: BoxDecoration(
        gradient: enabled ? colors.primaryAuroraGradient : null,
        color: enabled ? null : colors.surfaceGlassHover,
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.accentCyan.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (isLoading) ...<Widget>[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFF05070E),
              ),
            ),
            const SizedBox(width: 10),
          ] else if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 18,
              color: enabled ? const Color(0xFF05070E) : colors.textMuted,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: enabled ? const Color(0xFF05070E) : colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? () {
                HapticsHelper.lightImpact();
                onPressed!();
              }
            : null,
        child: fullWidth ? SizedBox(width: double.infinity, child: content) : content,
      ),
    );
  }
}

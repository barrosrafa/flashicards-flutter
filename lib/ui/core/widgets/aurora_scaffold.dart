import 'package:flutter/material.dart';

import '../theme/flashi_color_tokens.dart';
import 'edge_error_banner.dart';
import 'rate_limit_banner.dart';

/// Spatial Aurora scaffold providing radial ambient glows (`#00F2FE` & `#8B5CF6`),
/// integrated `EdgeErrorBanner` + `RateLimitBanner` overlays, and responsive safe areas.
class AuroraScaffold extends StatelessWidget {
  const AuroraScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      extendBody: extendBody,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Ambient Top-Right Cyan Radial Glow
          Positioned(
            top: -120,
            right: -90,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      colors.accentCyan.withValues(alpha: 0.14),
                      colors.accentCyan.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Ambient Bottom-Left Violet Radial Glow
          Positioned(
            bottom: -140,
            left: -100,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      colors.accentViolet.withValues(alpha: 0.14),
                      colors.accentViolet.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main Content + Global Edge/RateLimit Banners
          SafeArea(
            bottom: !extendBody,
            child: Column(
              children: <Widget>[
                const RateLimitBanner(),
                const EdgeErrorBanner(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

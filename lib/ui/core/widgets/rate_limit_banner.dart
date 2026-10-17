import 'package:flutter/material.dart';

import '../../../core/errors/edge_error_bus.dart';
import '../theme/flashi_color_tokens.dart';
import '../theme/flashi_typography.dart';

/// Global banner listening to [EdgeErrorBus] to display HTTP 429 rate-limit
/// countdown notifications (`Retry-After`).
///
/// Mirrors `src/components/shared/rate-limit-banner.tsx` from `app-flashi`.
class RateLimitBanner extends StatelessWidget {
  const RateLimitBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return ListenableBuilder(
      listenable: EdgeErrorBus.instance,
      builder: (BuildContext context, _) {
        final EdgeErrorEvent? event = EdgeErrorBus.instance.latestError;
        if (event == null || !event.isRateLimited) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.ratingHard.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.ratingHard.withValues(alpha: 0.50),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.hourglass_top_rounded,
                size: 18,
                color: colors.ratingHard,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (event.retryAfterSeconds != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgCanvas.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${event.retryAfterSeconds}s',
                    style: FlashiTypography.monoMetric(
                      color: colors.ratingHard,
                      fontSize: 11,
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
                onPressed: EdgeErrorBus.instance.dismissLatest,
              ),
            ],
          ),
        );
      },
    );
  }
}

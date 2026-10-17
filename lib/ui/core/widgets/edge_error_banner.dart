import 'package:flutter/material.dart';

import '../../../core/errors/edge_error_bus.dart';
import '../theme/flashi_color_tokens.dart';
import '../theme/flashi_typography.dart';

/// Global banner listening to [EdgeErrorBus] to surface non-rate-limit Edge Function
/// errors with their `request_id` for rapid diagnostics.
///
/// Mirrors `src/components/shared/edge-error-banner.tsx` from `app-flashi`.
class EdgeErrorBanner extends StatelessWidget {
  const EdgeErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return ListenableBuilder(
      listenable: EdgeErrorBus.instance,
      builder: (BuildContext context, _) {
        final EdgeErrorEvent? event = EdgeErrorBus.instance.latestError;
        if (event == null || event.isRateLimited) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.ratingAgain.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.ratingAgain.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: colors.ratingAgain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (event.requestId != null)
                      Text(
                        'req_id: ${event.requestId}',
                        style: FlashiTypography.monoMetric(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
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

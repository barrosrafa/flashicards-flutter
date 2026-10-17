import 'package:flutter/material.dart';

import '../../../data/local/sync_engine.dart';
import '../theme/flashi_color_tokens.dart';
import '../theme/flashi_typography.dart';

/// Compact Sync Status Orb Pill that displays live USN cursor, pending outbox
/// mutations count, and triggers `SyncEngine.syncNow()` on tap.
///
/// Mirrors `src/components/shared/sync-status-panel.tsx` from `app-flashi`.
class SyncStatusOrbPanel extends StatelessWidget {
  const SyncStatusOrbPanel({
    super.key,
    required this.syncEngine,
  });

  final SyncEngine syncEngine;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        syncEngine,
        syncEngine.outboxQueue,
      ]),
      builder: (BuildContext context, _) {
        final bool syncing = syncEngine.isSyncing;
        final int pending = syncEngine.outboxQueue.pendingCount;
        final Color orbColor = syncing
            ? colors.accentCyan
            : (pending > 0 ? colors.ratingHard : colors.ratingGood);

        final String label = syncing
            ? 'Sincronizando...'
            : (pending > 0
                ? 'Offline · $pending na fila'
                : 'Sincronizado · USN ${syncEngine.lastUsn}');

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: syncing ? null : syncEngine.syncNow,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceGlassPrimary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.borderSpecular),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orbColor,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: orbColor.withValues(alpha: 0.65),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: FlashiTypography.monoMetric(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

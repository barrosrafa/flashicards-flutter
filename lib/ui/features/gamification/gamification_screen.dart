import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/gamification.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Gamification Hub (`/gamification`) displaying XP, Level ($\lfloor\sqrt{\text{XP}/100}\rfloor + 1$),
/// Streak Freezes, Unlocked Badges, and Global Leaderboard.
///
/// Mirrors `src/components/gamification/gamification-header.tsx` and `gamification-service.ts` from `app-flashi`.
class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  GamificationProfile? _profile;
  List<UserBadge> _badges = const <UserBadge>[];
  List<LeaderboardEntry> _leaderboard = const <LeaderboardEntry>[];

  @override
  void initState() {
    super.initState();
    _loadGamification();
  }

  Future<void> _loadGamification() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final String userId = locator.activeUserId;
    final GamificationProfile profile =
        await locator.gamificationRepository.getProfile(userId);
    final List<UserBadge> badges =
        await locator.gamificationRepository.getUserBadges(userId);
    final List<LeaderboardEntry> leaders =
        await locator.gamificationRepository.getLeaderboard();

    if (!mounted) {
      return;
    }
    setState(() {
      _profile = profile;
      _badges = badges;
      _leaderboard = leaders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final GamificationProfile? p = _profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/profile'),
            ),
            Expanded(
              child: Text(
                'Conquistas & Ranking Global',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        GlassBentoCard(
          accentBorderColor: colors.accentCyan,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _StatColumn(
                label: 'NIVEL',
                value: '${p?.level ?? 2}',
                color: colors.accentCyan,
              ),
              _StatColumn(
                label: 'XP TOTAL',
                value: '${p?.totalXp ?? 180}',
                color: colors.accentViolet,
              ),
              _StatColumn(
                label: 'OFENSIVA',
                value: '${p?.currentStreak ?? 3}d',
                color: colors.ratingHard,
              ),
              _StatColumn(
                label: 'FREEZES',
                value: '${p?.streakFreezesAvailable ?? 2}',
                color: colors.ratingEasy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Insignias Desbloqueadas (${_badges.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ..._badges.map(
          (UserBadge b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassBentoCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.accentViolet.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: colors.accentViolet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          b.badge?.name ?? b.badgeId,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (b.badge?.description != null)
                          Text(
                            b.badge!.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Leaderboard Neural',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ..._leaderboard.asMap().entries.map(
          (MapEntry<int, LeaderboardEntry> entry) {
            final int rank = entry.key + 1;
            final LeaderboardEntry leader = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassBentoCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Text(
                      '#$rank',
                      style: FlashiTypography.monoMetric(
                        color: rank == 1 ? colors.ratingHard : colors.accentCyan,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            leader.displayName ?? 'Estudante Flashi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Nivel ${leader.level} · Ofensiva ${leader.currentStreak}d',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${leader.totalXp} XP',
                      style: FlashiTypography.monoMetric(
                        color: colors.accentCyan,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: FlashiTypography.monoMetric(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

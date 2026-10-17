import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../domain/models/deck.dart';
import '../../../domain/models/deck_exam.dart';
import '../../../domain/models/gamification.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/glass_bento_card.dart';
import '../../core/widgets/sync_status_orb_panel.dart';

/// Spatial Bento Grid Dashboard screen.
///
/// Mirrors `src/app/dashboard/page.tsx` from `app-flashi` with:
/// - Hero Study Orb Card (2x2 Bento) showing due, new, and learning counts
/// - Streak Flame & XP Level Ring (1x1 Bento)
/// - Exam Mode Countdown Alert Banner when an active exam exists
/// - Quick Action Pills (AI Ingest, Image Occlusion, Semantic Search, Marketplace)
/// - Active Decks list with 1-tap study launch
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  GamificationProfile? _gamification;
  List<DeckExam> _exams = const <DeckExam>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final ServiceLocator locator = ServiceLocator.instance;
    final String userId = locator.activeUserId;

    final DashboardData dashboard =
        await locator.dashboardRepository.getDashboardData(userId);
    final GamificationProfile gamification =
        await locator.gamificationRepository.getProfile(userId);
    final List<DeckExam> exams =
        await locator.examRepository.listActiveExams(userId: userId);

    if (!mounted) {
      return;
    }
    setState(() {
      _data = dashboard;
      _gamification = gamification;
      _exams = exams;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final ServiceLocator locator = ServiceLocator.instance;
    final DashboardData? data = _data;
    final GamificationProfile? gamification = _gamification;

    return RefreshIndicator(
      color: colors.accentCyan,
      onRefresh: () async {
        await locator.syncEngine.syncNow();
        await _loadDashboard();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: <Widget>[
          // Header Row + Live USN Sync Status Orb
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Flashi Spatial',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    locator.activeUserEmail,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
              SyncStatusOrbPanel(syncEngine: locator.syncEngine),
            ],
          ),
          const SizedBox(height: 18),

          // Exam Mode Alert Banner (if an active exam is scheduled)
          if (_exams.isNotEmpty) ...<Widget>[
            GlassBentoCard(
              padding: const EdgeInsets.all(16),
              accentBorderColor: colors.ratingHard,
              onTap: () => context.go('/exams'),
              child: Row(
                children: <Widget>[
                  Icon(Icons.timer_rounded, color: colors.ratingHard),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'MODO PROVA ATIVO · ${_exams.first.title}',
                          style: FlashiTypography.monoMetric(
                            color: colors.ratingHard,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Faltam ${_exams.first.daysRemaining} dias · Boost FSRS ${_exams.first.computeIntervalBoostMultiplier().toStringAsFixed(2)}x',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Hero Study Orb Bento Card (2x2)
          GlassBentoCard(
            accentBorderColor: colors.accentCyan.withValues(alpha: 0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'SESSAO FSRS-6 DE HOJE',
                        style: FlashiTypography.monoMetric(
                          color: colors.accentCyan,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.search_rounded,
                        color: colors.textSecondary,
                      ),
                      tooltip: 'Busca Semantica IA',
                      onPressed: () => context.go('/search'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _loading
                      ? 'Calculando fila neural...'
                      : '${data?.dueCount ?? 0} cartoes prontos para revisao',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    _MetricPill(
                      label: 'Novos',
                      count: data?.newCount ?? 0,
                      color: colors.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    _MetricPill(
                      label: 'Aprendendo',
                      count: data?.learningCount ?? 0,
                      color: colors.ratingHard,
                    ),
                    const SizedBox(width: 8),
                    _MetricPill(
                      label: 'Revisao',
                      count: data?.reviewCount ?? 0,
                      color: colors.ratingGood,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                CyberPrimaryButton(
                  label: (data?.dueCount ?? 0) > 0
                      ? 'Estudar Agora (${data!.dueCount})'
                      : 'Praticar Sessao Rapida',
                  icon: Icons.bolt_rounded,
                  fullWidth: true,
                  onPressed: () => context.go('/study'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bento Row: Streak Flame (1x1) + XP Level (1x1)
          Row(
            children: <Widget>[
              Expanded(
                child: GlassBentoCard(
                  onTap: () => context.go('/gamification'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: colors.ratingHard,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'OFENSIVA',
                            style: FlashiTypography.monoMetric(
                              color: colors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${gamification?.currentStreak ?? 3} dias',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Recorde: ${gamification?.longestStreak ?? 7}d',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassBentoCard(
                  onTap: () => context.go('/analytics'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.auto_graph_rounded,
                            color: colors.accentViolet,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'NIVEL ${gamification?.level ?? 2}',
                            style: FlashiTypography.monoMetric(
                              color: colors.accentViolet,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${gamification?.totalXp ?? 180} XP',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Ver telemetria ->',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Spatial Pills
          Text(
            'Acoes Rapidas & IA',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _QuickActionChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Gerar com IA',
                  onTap: () => context.go('/ingest'),
                ),
                const SizedBox(width: 10),
                _QuickActionChip(
                  icon: Icons.crop_free_rounded,
                  label: 'Oclusao de Imagem',
                  onTap: () => context.go('/occlusion'),
                ),
                const SizedBox(width: 10),
                _QuickActionChip(
                  icon: Icons.swap_vert_circle_rounded,
                  label: 'Anki .apkg',
                  onTap: () => context.go('/anki'),
                ),
                const SizedBox(width: 10),
                _QuickActionChip(
                  icon: Icons.explore_rounded,
                  label: 'Comunidade',
                  onTap: () => context.go('/explore'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Decks Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Seus Baralhos (${data?.totalDecks ?? 0})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () => context.go('/decks'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Gerenciar'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if ((data?.decks ?? const <Deck>[]).isEmpty && !_loading)
            GlassBentoCard(
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.layers_clear_rounded,
                    size: 38,
                    color: colors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  const Text('Nenhum baralho criado ainda.'),
                  const SizedBox(height: 12),
                  CyberPrimaryButton(
                    label: 'Criar Deck Inicial Guiado',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () => context.go('/onboarding'),
                  ),
                ],
              ),
            )
          else
            ...(data?.decks ?? const <Deck>[]).take(6).map(
                  (Deck deck) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassBentoCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => context.go('/decks/${deck.id}'),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colors.accentCyan.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.folder_special_rounded,
                              color: colors.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  deck.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                if (deck.description != null &&
                                    deck.description!.isNotEmpty)
                                  Text(
                                    deck.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.play_circle_fill_rounded,
                              color: colors.accentCyan,
                              size: 28,
                            ),
                            onPressed: () =>
                                context.go('/study?deckId=${deck.id}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: <Widget>[
            Text(
              '$count',
              style: FlashiTypography.monoMetric(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceGlassPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSpecular),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: colors.accentCyan),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/crypto_utils.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../domain/models/deck_exam.dart';
import '../../../domain/models/due_card.dart';
import '../../../domain/models/gamification.dart';
import '../../../domain/models/review_result.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/glass_bento_card.dart';
import '../socratic/socratic_tutor_sheet.dart';

/// Spatial 3D Study Player with:
/// - Perspective `Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(...)` 3D flip
/// - Ergonomic Thumb-Zone FSRS-6 4-Rating Dock (`Again`, `Hard`, `Good`, `Easy`)
/// - Exam Mode FSRS boost multiplier integration
/// - Socratic AI Tutor trigger on lapsed (`Again`) cards
/// - Session XP & Streak confirmation modal on completion
///
/// Mirrors `src/app/study/page.tsx` and `src/components/study/study-session-player.tsx` from `app-flashi`.
class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({
    super.key,
    this.deckId,
  });

  final String? deckId;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  final String _sessionId = CryptoUtils.generateUuidV4();
  final List<String> _sessionReviewKeys = <String>[];

  List<DueCard> _queue = const <DueCard>[];
  int _currentIndex = 0;
  bool _isRevealed = false;
  bool _loading = true;
  bool _isSubmitting = false;
  double _examBoostMultiplier = 1.0;
  DateTime _cardShownAt = DateTime.now();
  SessionXpResult? _xpResult;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _loadSession();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() => _loading = true);
    final ServiceLocator locator = ServiceLocator.instance;
    final String userId = locator.activeUserId;

    final List<DueCard> due = await locator.studyRepository.getDueCards(
      userId: userId,
      deckId: widget.deckId,
    );
    final List<DeckExam> activeExams = await locator.examRepository
        .listActiveExams(userId: userId, deckId: widget.deckId);

    final double boost = activeExams.isNotEmpty
        ? activeExams.first.computeIntervalBoostMultiplier()
        : 1.0;

    if (!mounted) {
      return;
    }
    setState(() {
      _queue = (due.isEmpty && userId == 'demo-user-id') ? demoCards : due;
      _currentIndex = 0;
      _isRevealed = false;
      _examBoostMultiplier = boost;
      _cardShownAt = DateTime.now();
      _loading = false;
    });
  }

  void _toggleFlip() {
    HapticsHelper.selectionClick();
    if (_isRevealed) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isRevealed = !_isRevealed;
    });
  }

  Future<void> _submitRating(ReviewRating rating) async {
    if (_isSubmitting || _currentIndex >= _queue.length) {
      return;
    }
    _isSubmitting = true;
    HapticsHelper.forReviewRating(rating.value);
    final ServiceLocator locator = ServiceLocator.instance;
    final DueCard card = _queue[_currentIndex];
    final int durationMs =
        DateTime.now().difference(_cardShownAt).inMilliseconds.clamp(300, 120000);

    try {
      await locator.studyRepository.submitReview(
        userId: locator.activeUserId,
        card: card,
        rating: rating,
        durationMs: durationMs,
        sessionId: _sessionId,
        examBoostMultiplier: _examBoostMultiplier,
      );
      _sessionReviewKeys.add('${card.cardId}:${_sessionReviewKeys.length}');

      // If user rated Again on a previously reviewed card, offer Socratic AI remediation
      if (rating == ReviewRating.again && mounted) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) => SocraticTutorSheet(
            cardId: card.cardId,
            cardFront: card.front,
            cardBack: card.back,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      if (_currentIndex + 1 >= _queue.length) {
        final SessionXpResult xp =
            await locator.gamificationRepository.syncSessionXp(
          userId: locator.activeUserId,
          sessionId: _sessionId,
          reviewKeys: _sessionReviewKeys,
          localXpGained: _queue.length * 15,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _xpResult = xp;
        });
        return;
      }

      _flipController.reset();
      setState(() {
        _currentIndex++;
        _isRevealed = false;
        _cardShownAt = DateTime.now();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_xpResult != null) {
      return _SessionCompletedView(
        xpResult: _xpResult!,
        reviewedCount: _queue.length,
        onRestart: () {
          setState(() => _xpResult = null);
          _loadSession();
        },
        onDashboard: () => context.go('/dashboard'),
      );
    }

    if (_queue.isEmpty || _currentIndex >= _queue.length) {
      return _EmptyQueueView(
        onRefresh: _loadSession,
        onExplore: () => context.go('/explore'),
        onDashboard: () => context.go('/dashboard'),
      );
    }

    final DueCard currentCard = _queue[_currentIndex];
    final Map<ReviewRating, String> intervals =
        ServiceLocator.instance.studyRepository.previewIntervals(
      currentCard,
      examBoostMultiplier: _examBoostMultiplier,
    );
    final double progress = (_currentIndex + 1) / _queue.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        children: <Widget>[
          // Top Progress Bar & Exam Mode Indicator
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.go('/dashboard'),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: colors.surfaceGlassPrimary,
                    color: colors.accentCyan,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentIndex + 1}/${_queue.length}',
                style: FlashiTypography.monoMetric(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.psychology_alt_rounded,
                  color: colors.accentViolet,
                ),
                tooltip: 'Abrir Tutor Socratico IA',
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SocraticTutorSheet(
                      cardId: currentCard.cardId,
                      cardFront: currentCard.front,
                      cardBack: currentCard.back,
                    ),
                  );
                },
              ),
            ],
          ),
          if (_examBoostMultiplier > 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'MODO PROVA ATIVO · COMPRESSAO DE INTERVALO ${_examBoostMultiplier.toStringAsFixed(2)}x',
                style: FlashiTypography.monoMetric(
                  color: colors.ratingHard,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 3D Perspective Flashcard Canvas
          Expanded(
            child: Semantics(
              button: true,
              label: _isRevealed
                  ? 'Virar cartao para a frente'
                  : 'Virar cartao para o verso',
              child: GestureDetector(
                onTap: _toggleFlip,
                child: AnimatedBuilder(
                animation: _flipController,
                builder: (BuildContext context, _) {
                  final double angle = _flipController.value * math.pi;
                  final bool showBack = angle >= (math.pi / 2);
                  final Matrix4 transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle);

                  return Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: showBack
                          ? (Matrix4.identity()..rotateY(math.pi))
                          : Matrix4.identity(),
                      child: GlassBentoCard(
                        accentBorderColor: showBack
                            ? colors.accentViolet.withValues(alpha: 0.55)
                            : colors.accentCyan.withValues(alpha: 0.45),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    color: (showBack
                                            ? colors.accentViolet
                                            : colors.accentCyan)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    showBack
                                        ? 'VERSO · RESPOSTA'
                                        : 'FRENTE · ${currentCard.cardType.toUpperCase()}',
                                    style: FlashiTypography.monoMetric(
                                      color: showBack
                                          ? colors.accentViolet
                                          : colors.accentCyan,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  'S=${currentCard.stability.toStringAsFixed(1)} · D=${currentCard.difficulty.toStringAsFixed(1)}',
                                  style: FlashiTypography.monoMetric(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      showBack
                                          ? currentCard.back
                                          : currentCard.front,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    if (showBack &&
                                        currentCard.extra != null &&
                                        currentCard.extra!.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 16),
                                      Text(
                                        currentCard.extra!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Center(
                              child: Text(
                                showBack
                                    ? 'Escolha sua avaliacao FSRS-6 no dock abaixo'
                                    : 'Toque no cartao para virar em 3D',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Thumb-Zone FSRS-6 Rating Dock
          if (!_isRevealed)
            Semantics(
              button: true,
              label: 'Mostrar resposta do cartao',
              child: CyberPrimaryButton(
                label: 'Mostrar Resposta',
                icon: Icons.flip_rounded,
                fullWidth: true,
                onPressed: _toggleFlip,
              ),
            )
          else
            Row(
              children: <Widget>[
                _FsrsRatingButton(
                  label: 'De novo',
                  interval: intervals[ReviewRating.again] ?? '<10m',
                  color: colors.ratingAgain,
                  onTap: () => _submitRating(ReviewRating.again),
                ),
                const SizedBox(width: 8),
                _FsrsRatingButton(
                  label: 'Dificil',
                  interval: intervals[ReviewRating.hard] ?? '2d',
                  color: colors.ratingHard,
                  onTap: () => _submitRating(ReviewRating.hard),
                ),
                const SizedBox(width: 8),
                _FsrsRatingButton(
                  label: 'Bom',
                  interval: intervals[ReviewRating.good] ?? '5d',
                  color: colors.ratingGood,
                  onTap: () => _submitRating(ReviewRating.good),
                ),
                const SizedBox(width: 8),
                _FsrsRatingButton(
                  label: 'Facil',
                  interval: intervals[ReviewRating.easy] ?? '12d',
                  color: colors.ratingEasy,
                  onTap: () => _submitRating(ReviewRating.easy),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FsrsRatingButton extends StatelessWidget {
  const _FsrsRatingButton({
    required this.label,
    required this.interval,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String interval;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Avaliar como $label, proximo intervalo em $interval',
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.50)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                interval,
                style: FlashiTypography.monoMetric(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _SessionCompletedView extends StatelessWidget {
  const _SessionCompletedView({
    required this.xpResult,
    required this.reviewedCount,
    required this.onRestart,
    required this.onDashboard,
  });

  final SessionXpResult xpResult;
  final int reviewedCount;
  final VoidCallback onRestart;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassBentoCard(
          accentBorderColor: colors.ratingGood,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.ratingGood.withValues(alpha: 0.16),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 46,
                  color: colors.ratingGood,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sessao Neural Concluida!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Voce revisou $reviewedCount cartoes com FSRS-6 e ganhou +${xpResult.xpGained} XP.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        '${xpResult.totalXp} XP',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Nivel ${xpResult.newLevel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        '${xpResult.newStreak} dias',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Ofensiva ativa',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.ratingHard,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              CyberPrimaryButton(
                label: 'Voltar ao Dashboard',
                icon: Icons.check_rounded,
                fullWidth: true,
                onPressed: onDashboard,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRestart,
                child: const Text('Praticar Mais Cartoes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyQueueView extends StatelessWidget {
  const _EmptyQueueView({
    required this.onRefresh,
    required this.onExplore,
    required this.onDashboard,
  });

  final VoidCallback onRefresh;
  final VoidCallback onExplore;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassBentoCard(
          accentBorderColor: colors.ratingGood,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.ratingGood.withValues(alpha: 0.16),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 46,
                  color: colors.ratingGood,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fila Concluida!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Voce revisou todos os cartoes programados para agora. O algoritmo FSRS-6 recalculara os proximos vencimentos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              CyberPrimaryButton(
                label: 'Voltar ao Dashboard',
                icon: Icons.dashboard_rounded,
                fullWidth: true,
                onPressed: onDashboard,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: colors.borderSpecular),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(Icons.explore_rounded, color: colors.accentCyan),
                label: Text(
                  'Explorar Baralhos Publicos',
                  style: TextStyle(color: colors.textPrimary),
                ),
                onPressed: onExplore,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Recarregar Fila'),
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


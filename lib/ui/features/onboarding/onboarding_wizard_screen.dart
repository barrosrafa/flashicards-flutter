import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../domain/models/learning_preferences.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/widgets/aurora_scaffold.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Two-step Onboarding Wizard that personalizes daily FSRS limits and provisions
/// a 5-card Starter Deck tailored to the user's goal (`vestibular`, `idiomas`,
/// `concursos`, or `carreira`).
///
/// Mirrors `src/app/Onboarding/page.tsx` from `app-flashi`.
class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  LearningGoal _selectedGoal = LearningGoal.vestibular;
  int _selectedMinutes = 15;
  bool _isProvisioning = false;

  Future<void> _completeOnboarding() async {
    setState(() {
      _isProvisioning = true;
    });
    try {
      final ServiceLocator locator = ServiceLocator.instance;
      final ActivationResult result =
          await locator.onboardingRepository.completeActivation(
        userId: locator.activeUserId,
        preferences: LearningPreferences(
          goal: _selectedGoal,
          dailyMinutes: _selectedMinutes,
        ),
      );
      if (!mounted) {
        return;
      }
      context.go('/study?deckId=${result.deckId}');
    } finally {
      if (mounted) {
        setState(() {
          _isProvisioning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final LearningDraft previewDraft =
        starterDraftByGoal[_selectedGoal] ??
            starterDraftByGoal[LearningGoal.vestibular]!;

    return AuroraScaffold(
      extendBody: false,
      appBar: AppBar(
        title: const Text('Configuracao Neural Inicial'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            '1. Qual e o seu foco principal?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Criaremos um baralho inicial com 5 cartoes prontos para sua primeira sessao.',
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _GoalOptionCard(
                goal: LearningGoal.vestibular,
                title: 'Vestibular & ENEM',
                subtitle: 'Biologia, Fisica, Matematica e Humanas',
                icon: Icons.school_rounded,
                selected: _selectedGoal == LearningGoal.vestibular,
                onTap: () => setState(() => _selectedGoal = LearningGoal.vestibular),
              ),
              _GoalOptionCard(
                goal: LearningGoal.idiomas,
                title: 'Idiomas & Fluencia',
                subtitle: 'Phrasal verbs, expressoes e vocabulario ativo',
                icon: Icons.translate_rounded,
                selected: _selectedGoal == LearningGoal.idiomas,
                onTap: () => setState(() => _selectedGoal = LearningGoal.idiomas),
              ),
              _GoalOptionCard(
                goal: LearningGoal.concursos,
                title: 'Concursos & OAB',
                subtitle: 'Direito Constitucional, Portugues e Logica',
                icon: Icons.gavel_rounded,
                selected: _selectedGoal == LearningGoal.concursos,
                onTap: () => setState(() => _selectedGoal = LearningGoal.concursos),
              ),
              _GoalOptionCard(
                goal: LearningGoal.carreira,
                title: 'Carreira & Tech',
                subtitle: 'Produtividade, entrevistas e gestao de produto',
                icon: Icons.rocket_launch_rounded,
                selected: _selectedGoal == LearningGoal.carreira,
                onTap: () => setState(() => _selectedGoal = LearningGoal.carreira),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            '2. Ritmo diario de estudo',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: <int>[5, 15, 30].map((int mins) {
              final bool isSelected = _selectedMinutes == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GlassBentoCard(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    accentBorderColor: isSelected ? colors.accentCyan : null,
                    onTap: () {
                      HapticsHelper.selectionClick();
                      setState(() => _selectedMinutes = mins);
                    },
                    child: Column(
                      children: <Widget>[
                        Text(
                          '$mins min',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isSelected
                                    ? colors.accentCyan
                                    : colors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dailyMinutesToNewCardsLimit(mins)} novos/dia',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          GlassBentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'DECK INICIAL: ${previewDraft.title.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.accentCyan,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  previewDraft.description,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                ...previewDraft.cards.take(2).map(
                      (StarterCardDraft c) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: colors.ratingGood,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.front,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CyberPrimaryButton(
            label: 'Criar Deck e Iniciar 1a Sessao (5 Cartoes)',
            icon: Icons.bolt_rounded,
            isLoading: _isProvisioning,
            fullWidth: true,
            onPressed: _completeOnboarding,
          ),
        ],
      ),
    );
  }
}

class _GoalOptionCard extends StatelessWidget {
  const _GoalOptionCard({
    required this.goal,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final LearningGoal goal;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    return GlassBentoCard(
      accentBorderColor: selected ? colors.accentCyan : null,
      onTap: () {
        HapticsHelper.selectionClick();
        onTap();
      },
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (selected ? colors.accentCyan : colors.accentViolet)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: selected ? colors.accentCyan : colors.accentViolet,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: colors.accentCyan),
        ],
      ),
    );
  }
}

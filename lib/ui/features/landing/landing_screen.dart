import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../domain/models/due_card.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/aurora_scaffold.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Spatial Aurora ("Cyber-Glass") Landing Screen with an interactive 3-card
/// FSRS-6 demo player so users can experience Flashi before signing in.
///
/// Mirrors `src/app/page.tsx` and `src/components/study/demo-study-player.tsx` from `app-flashi`.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _demoIndex = 0;
  bool _revealed = false;

  void _flipCard() {
    HapticsHelper.selectionClick();
    setState(() {
      _revealed = !_revealed;
    });
  }

  void _rateDemoCard() {
    HapticsHelper.mediumImpact();
    setState(() {
      _revealed = false;
      _demoIndex = (_demoIndex + 1) % demoCards.length;
    });
  }

  Future<void> _enterInstantDemo() async {
    await ServiceLocator.instance.authRepository.startDemoSession();
    if (!mounted) {
      return;
    }
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final DueCard activeDemo = demoCards[_demoIndex];

    return AuroraScaffold(
      extendBody: false,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: colors.primaryAuroraGradient,
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF05070E),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Flashi'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              'Entrar',
              style: TextStyle(
                color: colors.accentCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: <Widget>[
          // Badge Pill
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colors.accentCyan.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'MOTOR NEURAL FSRS-6 · OFFLINE-FIRST',
                style: FlashiTypography.monoMetric(
                  color: colors.accentCyan,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memorizacao de alta precisao com Inteligencia Espacial.',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Algoritmo FSRS-6 de 21 pesos, Tutor Socratico por IA, Oclusao de Imagem multi-toque e sincronizacao offline instantanea.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: CyberPrimaryButton(
                  label: 'Comecar Agora',
                  icon: Icons.rocket_launch_rounded,
                  fullWidth: true,
                  onPressed: () => context.go('/register'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: colors.borderSpecular),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _enterInstantDemo,
                  icon: Icon(Icons.play_arrow_rounded, color: colors.accentCyan),
                  label: Text(
                    'Modo Demo',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Interactive 3-Card Demo Player
          GlassBentoCard(
            accentBorderColor: colors.accentCyan.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'EXPERIMENTE AGORA (${_demoIndex + 1}/${demoCards.length})',
                      style: FlashiTypography.monoMetric(
                        color: colors.accentCyan,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _revealed ? 'VERSO (RESPOSTA)' : 'FRENTE (PERGUNTA)',
                      style: FlashiTypography.monoMetric(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _flipCard,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colors.bgElevated.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.borderSpecular),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _revealed ? activeDemo.back : activeDemo.front,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _revealed
                              ? 'Avalie abaixo para simular o agendamento FSRS-6'
                              : 'Toque no cartao para revelar a resposta',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_revealed)
                  CyberPrimaryButton(
                    label: 'Revelar Resposta',
                    icon: Icons.flip_rounded,
                    fullWidth: true,
                    onPressed: _flipCard,
                  )
                else
                  Row(
                    children: <Widget>[
                      _DemoRateChip(
                        label: 'De novo',
                        interval: '<10m',
                        color: colors.ratingAgain,
                        onTap: _rateDemoCard,
                      ),
                      const SizedBox(width: 8),
                      _DemoRateChip(
                        label: 'Dificil',
                        interval: '2d',
                        color: colors.ratingHard,
                        onTap: _rateDemoCard,
                      ),
                      const SizedBox(width: 8),
                      _DemoRateChip(
                        label: 'Bom',
                        interval: '5d',
                        color: colors.ratingGood,
                        onTap: _rateDemoCard,
                      ),
                      const SizedBox(width: 8),
                      _DemoRateChip(
                        label: 'Facil',
                        interval: '12d',
                        color: colors.ratingEasy,
                        onTap: _rateDemoCard,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Feature Bento Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: const <Widget>[
              _FeatureTile(
                icon: Icons.psychology_rounded,
                title: 'FSRS-6 21 Pesos',
                subtitle: 'Otimizacao real baseada no seu historico de memoria.',
              ),
              _FeatureTile(
                icon: Icons.record_voice_over_rounded,
                title: 'Tutor Socratico',
                subtitle: 'Dialogo guiado por IA quando voce erra um cartao.',
              ),
              _FeatureTile(
                icon: Icons.crop_free_rounded,
                title: 'Oclusao Multi-Toque',
                subtitle: 'Crie mascaras sobre diagramas e imagens medicas.',
              ),
              _FeatureTile(
                icon: Icons.sync_bolt_rounded,
                title: 'Offline USN Sync',
                subtitle: 'Estude no aviao ou metro com sincronizacao automatica.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoRateChip extends StatelessWidget {
  const _DemoRateChip({
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Column(
            children: <Widget>[
              Text(
                interval,
                style: FlashiTypography.monoMetric(
                  color: color,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    return GlassBentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: colors.accentCyan, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

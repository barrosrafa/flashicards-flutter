import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/analytics_summary.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Analytics & FSRS-6 21-Weight Optimizer screen (`/analytics`).
///
/// Mirrors `src/app/analytics/page.tsx` and `src/components/analytics/fsrs-optimizer-card.tsx` from `app-flashi`.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsData? _analytics;
  FsrsOptimizationStatus? _optStatus;
  List<double> _weights = FsrsOptimizationStatus.defaultFsrs6Weights;
  bool _optimizing = false;

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  Future<void> _loadTelemetry() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final String userId = locator.activeUserId;
    final AnalyticsData data =
        await locator.analyticsRepository.getAnalytics(userId: userId);
    final FsrsOptimizationStatus opt =
        await locator.optimizerRepository.getStatus(userId);
    if (!mounted) {
      return;
    }
    setState(() {
      _analytics = data;
      _optStatus = opt;
      if (opt.currentWeights != null) {
        _weights = opt.currentWeights!;
      }
    });
  }

  Future<void> _triggerOptimization() async {
    setState(() => _optimizing = true);
    try {
      final ServiceLocator locator = ServiceLocator.instance;
      final List<double> updated = await locator.optimizerRepository
          .runOptimization(locator.activeUserId);
      if (!mounted) {
        return;
      }
      setState(() => _weights = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('21 pesos neurais FSRS-6 recalibrados com sucesso!'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _optimizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final AnalyticsData? data = _analytics;

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
                'Telemetria & Otimizador FSRS-6',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // KPI Summary Row
        Row(
          children: <Widget>[
            Expanded(
              child: GlassBentoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'RETENCAO VERDADEIRA',
                      style: FlashiTypography.monoMetric(
                        color: colors.ratingGood,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data?.accuracyRate ?? 92}%',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassBentoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'TOTAL REVISOES',
                      style: FlashiTypography.monoMetric(
                        color: colors.accentCyan,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data?.totalReviews ?? 0}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Activity Heatmap Grid
        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'MAPA DE CALOR DE REVISOES (ULTIMOS 14 DIAS)',
                style: FlashiTypography.monoMetric(
                  color: colors.accentCyan,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (data?.days ?? const <AnalyticsDay>[]).map(
                  (AnalyticsDay d) {
                    final double intensity =
                        (d.cardsReviewed / 30.0).clamp(0.18, 1.0);
                    return Tooltip(
                      message: '${d.date}: ${d.cardsReviewed} revisoes',
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.accentCyan.withValues(alpha: intensity),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${d.cardsReviewed}',
                          style: FlashiTypography.monoMetric(
                            color: colors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // FSRS-6 21-Parameter Optimizer Card
        GlassBentoCard(
          accentBorderColor: colors.accentViolet.withValues(alpha: 0.45),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'OTIMIZADOR NEURAL FSRS-6 (21 PARAMETROS)',
                style: FlashiTypography.monoMetric(
                  color: colors.accentViolet,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Progresso de coleta: ${_optStatus?.reviewCount ?? 0} / ${_optStatus?.minRequired ?? 400} revisoes registradas.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSpecular),
                ),
                child: Text(
                  'w = [${_weights.map((double w) => w.toStringAsFixed(4)).join(', ')}]',
                  style: FlashiTypography.monoMetric(
                    color: colors.accentCyan,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CyberPrimaryButton(
                label: 'Recalibrar 21 Pesos FSRS-6',
                icon: Icons.memory_rounded,
                isLoading: _optimizing,
                fullWidth: true,
                onPressed: _triggerOptimization,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/deck.dart';
import '../../../domain/models/deck_exam.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Exam Mode Target Date Scheduler (`/exams`) that computes dynamic FSRS-6
/// interval compression multipliers ($1.0 \le m \le 2.5$) as the exam date approaches.
///
/// Mirrors `src/components/exams/exam-scheduler-modal.tsx` from `app-flashi`.
class ExamSchedulerScreen extends StatefulWidget {
  const ExamSchedulerScreen({super.key});

  @override
  State<ExamSchedulerScreen> createState() => _ExamSchedulerScreenState();
}

class _ExamSchedulerScreenState extends State<ExamSchedulerScreen> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Prova de Residencia / ENEM',
  );
  List<Deck> _decks = const <Deck>[];
  List<DeckExam> _exams = const <DeckExam>[];
  String? _selectedDeckId;
  int _daysFromNow = 14;
  double _targetRetention = 0.95;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final List<Deck> decks =
        await locator.deckRepository.listDecks(userId: locator.activeUserId);
    final List<DeckExam> exams = await locator.examRepository
        .listActiveExams(userId: locator.activeUserId);
    if (!mounted) {
      return;
    }
    setState(() {
      _decks = decks;
      _exams = exams;
      if (decks.isNotEmpty) {
        _selectedDeckId = decks.first.id;
      }
    });
  }

  Future<void> _createExam() async {
    final ServiceLocator locator = ServiceLocator.instance;
    String deckId = _selectedDeckId ?? '';
    if (deckId.isEmpty) {
      final Deck d = await locator.deckRepository.createDeck(
        userId: locator.activeUserId,
        title: 'Deck Preparatorio de Prova',
      );
      deckId = d.id;
    }

    await locator.examRepository.createExam(
      userId: locator.activeUserId,
      deckId: deckId,
      title: _titleController.text,
      examDate: DateTime.now().add(Duration(days: _daysFromNow)),
      targetRetention: _targetRetention,
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

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
                'Modo Prova (Boost FSRS-6)',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Comprime dinamicamente os intervalos de revisao conforme a data da prova se aproxima para atingir 95%+ de retencao no dia do exame.',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),

        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FuturisticFormField(
                label: 'Nome da Prova / Exame',
                controller: _titleController,
              ),
              const SizedBox(height: 14),
              Text(
                'Dias ate a prova: $_daysFromNow dias',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _daysFromNow.toDouble(),
                min: 2,
                max: 60,
                divisions: 58,
                onChanged: (double v) =>
                    setState(() => _daysFromNow = v.round()),
              ),
              Text(
                'Retencao Alvo no Dia da Prova: ${(_targetRetention * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _targetRetention,
                min: 0.85,
                max: 0.99,
                divisions: 14,
                onChanged: (double v) => setState(() => _targetRetention = v),
              ),
              const SizedBox(height: 12),
              CyberPrimaryButton(
                label: 'Ativar Modo Prova',
                icon: Icons.timer_rounded,
                fullWidth: true,
                onPressed: _createExam,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Provas Ativas (${_exams.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ..._exams.map(
          (DeckExam exam) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassBentoCard(
              accentBorderColor: colors.ratingHard,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          exam.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data: ${exam.examDate} · Faltam ${exam.daysRemaining}d · Boost ${exam.computeIntervalBoostMultiplier().toStringAsFixed(2)}x',
                          style: FlashiTypography.monoMetric(
                            color: colors.ratingHard,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.check_circle_outline_rounded,
                      color: colors.ratingGood,
                    ),
                    onPressed: () async {
                      await ServiceLocator.instance.examRepository
                          .markExamCompleted(exam.id);
                      await _loadData();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/deck.dart';
import '../../../domain/models/ingestion_job.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// AI Document & Content Ingestion screen (`/ingest`) invoking `ingest-document`
/// to synthesize flashcards from PDFs, YouTube URLs, Webpages, or Markdown/Text.
///
/// Mirrors `src/app/ingest/page.tsx` from `app-flashi`.
class AiIngestionScreen extends StatefulWidget {
  const AiIngestionScreen({super.key});

  @override
  State<AiIngestionScreen> createState() => _AiIngestionScreenState();
}

class _AiIngestionScreenState extends State<AiIngestionScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  IngestionSourceType _sourceType = IngestionSourceType.text;
  List<Deck> _decks = const <Deck>[];
  List<IngestJob> _jobs = const <IngestJob>[];
  String? _selectedDeckId;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final List<Deck> decks =
        await locator.deckRepository.listDecks(userId: locator.activeUserId);
    final List<IngestJob> jobs =
        await locator.ingestionRepository.listJobs(userId: locator.activeUserId);
    if (!mounted) {
      return;
    }
    setState(() {
      _decks = decks;
      _jobs = jobs;
      if (decks.isNotEmpty) {
        _selectedDeckId = decks.first.id;
      }
    });
  }

  Future<void> _runIngestion() async {
    setState(() => _processing = true);
    try {
      final ServiceLocator locator = ServiceLocator.instance;
      String targetDeckId = _selectedDeckId ?? '';
      if (targetDeckId.isEmpty) {
        final Deck d = await locator.deckRepository.createDeck(
          userId: locator.activeUserId,
          title: 'Deck Sintetizado por IA',
        );
        targetDeckId = d.id;
      }

      final IngestJob job = await locator.ingestionRepository.startIngestion(
        userId: locator.activeUserId,
        deckId: targetDeckId,
        sourceType: _sourceType,
        rawContent: _contentController.text,
        sourceUrl: _urlController.text.isEmpty ? null : _urlController.text,
      );

      await _loadInitial();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sintese IA concluida! ${job.cardsGeneratedCount} cartoes gerados.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
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
              onPressed: () => context.go('/tools'),
            ),
            Expanded(
              child: Text(
                'Ingestao Neural por IA',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Extraia cartoes automaticamente de resumos, artigos cientificos, PDFs ou URLs do YouTube.',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),

        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: 8,
                children: IngestionSourceType.values.map((IngestionSourceType t) {
                  return ChoiceChip(
                    label: Text(t.value.toUpperCase()),
                    selected: _sourceType == t,
                    onSelected: (_) => setState(() => _sourceType = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              if (_decks.isNotEmpty) ...<Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _selectedDeckId,
                  decoration: const InputDecoration(
                    labelText: 'Deck de Destino',
                  ),
                  items: _decks
                      .map(
                        (Deck d) => DropdownMenuItem<String>(
                          value: d.id,
                          child: Text(d.title),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) => setState(() => _selectedDeckId = v),
                ),
                const SizedBox(height: 12),
              ],
              if (_sourceType == IngestionSourceType.youtube ||
                  _sourceType == IngestionSourceType.webpage)
                FuturisticFormField(
                  label: 'URL da Fonte',
                  controller: _urlController,
                  hintText: 'https://...',
                  prefixIcon: Icons.link_rounded,
                )
              else
                FuturisticFormField(
                  label: 'Conteudo ou Resumo Base',
                  controller: _contentController,
                  maxLines: 5,
                  hintText:
                      'Cole aqui o texto, apostila ou anotacoes da aula para gerar cartoes FSRS-6...',
                ),
              const SizedBox(height: 16),
              CyberPrimaryButton(
                label: 'Sintetizar Cartoes com IA',
                icon: Icons.auto_awesome_rounded,
                isLoading: _processing,
                fullWidth: true,
                onPressed: _runIngestion,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Historico de Ingestao (${_jobs.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ..._jobs.map(
          (IngestJob job) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassBentoCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        job.sourceType.value.toUpperCase(),
                        style: FlashiTypography.monoMetric(
                          color: colors.accentCyan,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${job.cardsGeneratedCount} cartoes gerados',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.ratingGood.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: FlashiTypography.monoMetric(
                        color: colors.ratingGood,
                        fontSize: 10,
                      ),
                    ),
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

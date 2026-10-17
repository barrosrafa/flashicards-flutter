import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/deck.dart';
import '../../../domain/models/ingestion_job.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Structured Deck File Import screen (`/import`) supporting `CSV`, `TSV`, `TXT`,
/// `JSON`, `Markdown`, and `XML` via `ImportRepository`.
///
/// Mirrors `src/app/import/page.tsx` from `app-flashi`.
class FileImportScreen extends StatefulWidget {
  const FileImportScreen({super.key});

  @override
  State<FileImportScreen> createState() => _FileImportScreenState();
}

class _FileImportScreenState extends State<FileImportScreen> {
  final TextEditingController _rawController = TextEditingController(
    text:
        'Qual a capital do Brasil?;Brasilia\nFormula da agua?;H2O\nVelocidade da luz no vacuo?;300.000 km/s',
  );
  ImportFormat _format = ImportFormat.csv;
  List<Deck> _decks = const <Deck>[];
  String? _selectedDeckId;
  ImportDeckResult? _lastResult;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final List<Deck> decks =
        await locator.deckRepository.listDecks(userId: locator.activeUserId);
    if (!mounted) {
      return;
    }
    setState(() {
      _decks = decks;
      if (decks.isNotEmpty) {
        _selectedDeckId = decks.first.id;
      }
    });
  }

  Future<void> _runImport() async {
    setState(() => _importing = true);
    try {
      final ServiceLocator locator = ServiceLocator.instance;
      String targetDeckId = _selectedDeckId ?? '';
      if (targetDeckId.isEmpty) {
        final Deck d = await locator.deckRepository.createDeck(
          userId: locator.activeUserId,
          title: 'Deck Importado (${_format.value.toUpperCase()})',
        );
        targetDeckId = d.id;
      }

      final ImportDeckResult res =
          await locator.importRepository.importStructuredFile(
        userId: locator.activeUserId,
        deckId: targetDeckId,
        format: _format,
        rawContent: _rawController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() => _lastResult = res);
    } finally {
      if (mounted) {
        setState(() => _importing = false);
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
                'Importar CSV / TSV / JSON / MD',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: 8,
                children: ImportFormat.values.map((ImportFormat f) {
                  return ChoiceChip(
                    label: Text(f.value.toUpperCase()),
                    selected: _format == f,
                    onSelected: (_) => setState(() => _format = f),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              if (_decks.isNotEmpty) ...<Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _selectedDeckId,
                  decoration: const InputDecoration(
                    labelText: 'Baralho de Destino',
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
              FuturisticFormField(
                label: 'Conteudo Estruturado (Frente;Verso)',
                controller: _rawController,
                maxLines: 6,
              ),
              const SizedBox(height: 16),
              CyberPrimaryButton(
                label: 'Importar Cartoes',
                icon: Icons.upload_file_rounded,
                isLoading: _importing,
                fullWidth: true,
                onPressed: _runImport,
              ),
            ],
          ),
        ),
        if (_lastResult != null) ...<Widget>[
          const SizedBox(height: 16),
          GlassBentoCard(
            accentBorderColor: colors.ratingGood,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Importacao Concluida!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Importados: ${_lastResult!.importedCount} · Ignorados: ${_lastResult!.failedCount}',
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 12),
                CyberPrimaryButton(
                  label: 'Abrir Baralho',
                  onPressed: () => context.go('/decks/${_lastResult!.deckId}'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

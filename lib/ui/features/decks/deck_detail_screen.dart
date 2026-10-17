import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/deck.dart';
import '../../../domain/models/flashcard.dart';
import '../../../domain/models/note.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Detailed deck view (`/decks/:deckId`) allowing note/card creation (`basic`,
/// `reversed`, `cloze`), per-deck FSRS settings overrides, and collaborator sharing.
///
/// Mirrors `src/app/decks/[id]/page.tsx` from `app-flashi`.
class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({
    super.key,
    required this.deckId,
  });

  final String deckId;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  Deck? _deck;
  List<Flashcard> _cards = const <Flashcard>[];
  List<DeckCollaborator> _collaborators = const <DeckCollaborator>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDeckDetails();
  }

  Future<void> _loadDeckDetails() async {
    setState(() => _loading = true);
    final ServiceLocator locator = ServiceLocator.instance;
    final Deck? deck = await locator.deckRepository.getDeck(widget.deckId);
    final List<Flashcard> cards = await locator.cardRepository.listCardsByDeck(
      deckId: widget.deckId,
      userId: locator.activeUserId,
    );
    final List<DeckCollaborator> collabs =
        await locator.collaboratorRepository.listCollaborators(widget.deckId);

    if (!mounted) {
      return;
    }
    setState(() {
      _deck = deck;
      _cards = cards;
      _collaborators = collabs;
      _loading = false;
    });
  }

  Future<void> _showAddNoteModal() async {
    final TextEditingController frontCtrl = TextEditingController();
    final TextEditingController backCtrl = TextEditingController();
    final TextEditingController extraCtrl = TextEditingController();
    String modelKind = 'basic';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        final FlashiColorTokens colors = modalContext.flashiColors;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: colors.borderSpecular),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Adicionar Nota / Cartao',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'basic',
                          label: Text('Basico'),
                        ),
                        ButtonSegment<String>(
                          value: 'reversed',
                          label: Text('Frente+Verso'),
                        ),
                        ButtonSegment<String>(
                          value: 'cloze',
                          label: Text('Cloze {{c1::}}'),
                        ),
                      ],
                      selected: <String>{modelKind},
                      onSelectionChanged: (Set<String> s) {
                        setModalState(() => modelKind = s.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    FuturisticFormField(
                      label: modelKind == 'cloze'
                          ? 'Texto Cloze (ex: A {{c1::mitocondria}} gera ATP)'
                          : 'Frente (Pergunta)',
                      controller: frontCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    FuturisticFormField(
                      label: modelKind == 'cloze'
                          ? 'Contexto Extra (opcional)'
                          : 'Verso (Resposta)',
                      controller: backCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    FuturisticFormField(
                      label: 'Notas Extras / Referencia (opcional)',
                      controller: extraCtrl,
                    ),
                    const SizedBox(height: 16),
                    CyberPrimaryButton(
                      label: 'Salvar Nota FSRS-6',
                      icon: Icons.check_rounded,
                      fullWidth: true,
                      onPressed: () async {
                        if (frontCtrl.text.trim().isEmpty) {
                          return;
                        }
                        final ServiceLocator locator = ServiceLocator.instance;
                        await locator.noteRepository.createNote(
                          userId: locator.activeUserId,
                          input: NoteInput(
                            deckId: widget.deckId,
                            modelKind: modelKind,
                            fieldValues: <String, String>{
                              'front': frontCtrl.text.trim(),
                              'back': backCtrl.text.trim(),
                              if (extraCtrl.text.trim().isNotEmpty)
                                'extra': extraCtrl.text.trim(),
                            },
                          ),
                        );
                        if (modalContext.mounted) {
                          Navigator.of(modalContext).pop();
                        }
                        await _loadDeckDetails();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeckSettingsDialog() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final DeckSettings current =
        await locator.deckSettingsRepository.getDeckSettings(
      userId: locator.activeUserId,
      deckId: widget.deckId,
    );
    final TextEditingController newLimitCtrl = TextEditingController(
      text: (current.dailyNewCardsLimit ?? 20).toString(),
    );
    final TextEditingController revLimitCtrl = TextEditingController(
      text: (current.dailyReviewsLimit ?? 200).toString(),
    );
    final TextEditingController retentionCtrl = TextEditingController(
      text: (current.desiredRetention ?? 0.90).toStringAsFixed(2),
    );

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ajustes FSRS-6 deste Deck'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FuturisticFormField(
                label: 'Novos cartoes por dia',
                controller: newLimitCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              FuturisticFormField(
                label: 'Maximo de revisoes por dia',
                controller: revLimitCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              FuturisticFormField(
                label: 'Retencao desejada (0.70 a 0.97)',
                controller: retentionCtrl,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await locator.deckSettingsRepository.saveDeckSettings(
                  DeckSettings(
                    userId: locator.activeUserId,
                    deckId: widget.deckId,
                    dailyNewCardsLimit: int.tryParse(newLimitCtrl.text) ?? 20,
                    dailyReviewsLimit: int.tryParse(revLimitCtrl.text) ?? 200,
                    desiredRetention:
                        (double.tryParse(retentionCtrl.text) ?? 0.90)
                            .clamp(0.70, 0.97),
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditCardModal(Flashcard card) async {
    final TextEditingController frontCtrl =
        TextEditingController(text: card.front);
    final TextEditingController backCtrl =
        TextEditingController(text: card.back);
    final TextEditingController extraCtrl =
        TextEditingController(text: card.extra ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        final FlashiColorTokens colors = modalContext.flashiColors;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: colors.borderSpecular),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Editar Cartao',
                  style: Theme.of(modalContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                FuturisticFormField(
                  label: 'Frente',
                  controller: frontCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                FuturisticFormField(
                  label: 'Verso',
                  controller: backCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                FuturisticFormField(
                  label: 'Notas Extras (opcional)',
                  controller: extraCtrl,
                ),
                const SizedBox(height: 16),
                CyberPrimaryButton(
                  label: 'Salvar Alteracoes',
                  icon: Icons.save_rounded,
                  fullWidth: true,
                  onPressed: () async {
                    if (frontCtrl.text.trim().isEmpty) return;
                    final Flashcard updated = card.copyWith(
                      front: frontCtrl.text.trim(),
                      back: backCtrl.text.trim(),
                      extra: extraCtrl.text.trim().isNotEmpty
                          ? extraCtrl.text.trim()
                          : null,
                    );
                    await ServiceLocator.instance.cardRepository
                        .updateCard(updated);
                    if (modalContext.mounted) {
                      Navigator.of(modalContext).pop();
                    }
                    await _loadDeckDetails();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
              onPressed: () => context.go('/decks'),
            ),
            Expanded(
              child: Text(
                _deck?.title ?? 'Baralho',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: 'Ajustes FSRS do Deck',
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showDeckSettingsDialog,
            ),
          ],
        ),
        if (_deck?.description != null && _deck!.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              _deck!.description!,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),

        // Action Bar
        Row(
          children: <Widget>[
            Expanded(
              child: CyberPrimaryButton(
                label: 'Estudar Deck (${_cards.length})',
                icon: Icons.bolt_rounded,
                fullWidth: true,
                onPressed: () => context.go('/study?deckId=${widget.deckId}'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: colors.borderSpecular),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _showAddNoteModal,
                icon: Icon(Icons.add_rounded, color: colors.accentCyan),
                label: Text(
                  'Nova Nota',
                  style: TextStyle(color: colors.textPrimary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_collaborators.isNotEmpty) ...<Widget>[
          Text(
            'Colaboradores (${_collaborators.length})',
            style: FlashiTypography.monoMetric(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
        ],

        Text(
          'Cartoes no Baralho (${_cards.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),

        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_cards.isEmpty)
          GlassBentoCard(
            child: Column(
              children: <Widget>[
                const Text('Nenhum cartao neste baralho ainda.'),
                const SizedBox(height: 12),
                CyberPrimaryButton(
                  label: 'Adicionar Primeiro Cartao',
                  icon: Icons.add_rounded,
                  onPressed: _showAddNoteModal,
                ),
              ],
            ),
          )
        else
          ..._cards.map(
            (Flashcard card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassBentoCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentCyan.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        card.cardType.toUpperCase(),
                        style: FlashiTypography.monoMetric(
                          color: colors.accentCyan,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            card.front,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.back,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: colors.textMuted,
                      ),
                      tooltip: 'Editar cartao',
                      onPressed: () => _showEditCardModal(card),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: colors.textMuted,
                      ),
                      tooltip: 'Excluir cartao',
                      onPressed: () async {
                        await ServiceLocator.instance.cardRepository
                            .deleteCard(card.id);
                        await _loadDeckDetails();
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

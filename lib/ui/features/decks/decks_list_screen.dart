import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/deck.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Hierarchical Decks Manager (`/decks`) and Public Deck Marketplace (`/explore`).
///
/// Mirrors `src/app/decks/page.tsx` and `src/app/explore/page.tsx` from `app-flashi`:
/// - Supports up to 5 levels of nested sub-decks (`parent_deck_id`).
/// - Supports public deck search and 1-tap `clone_public_deck` cloning.
class DecksListScreen extends StatefulWidget {
  const DecksListScreen({
    super.key,
    this.initialMarketplaceTab = false,
  });

  final bool initialMarketplaceTab;

  @override
  State<DecksListScreen> createState() => _DecksListScreenState();
}

class _DecksListScreenState extends State<DecksListScreen> {
  List<Deck> _myDecks = const <Deck>[];
  List<Deck> _publicDecks = const <Deck>[];
  bool _showMarketplace = false;
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showMarketplace = widget.initialMarketplaceTab;
    _loadDecks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    setState(() => _loading = true);
    final ServiceLocator locator = ServiceLocator.instance;
    final List<Deck> mine = await locator.deckRepository.listDecks(
      userId: locator.activeUserId,
    );
    final List<Deck> pub = await locator.deckRepository.listPublicDecks(
      searchQuery: _searchController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _myDecks = mine;
      _publicDecks = pub;
      _loading = false;
    });
  }

  Future<void> _showCreateDeckDialog({String? parentDeckId}) async {
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    DeckVisibility visibility = DeckVisibility.private;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: Text(
                parentDeckId == null ? 'Novo Baralho' : 'Novo Sub-baralho',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FuturisticFormField(
                    label: 'Titulo do Deck',
                    controller: titleCtrl,
                    hintText: 'Ex: Cardiologia Clinica',
                  ),
                  const SizedBox(height: 12),
                  FuturisticFormField(
                    label: 'Descricao (opcional)',
                    controller: descCtrl,
                    hintText: 'Resumo do conteudo',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DeckVisibility>(
                    initialValue: visibility,
                    decoration: const InputDecoration(
                      labelText: 'Visibilidade',
                    ),
                    items: const <DropdownMenuItem<DeckVisibility>>[
                      DropdownMenuItem<DeckVisibility>(
                        value: DeckVisibility.private,
                        child: Text('Privado'),
                      ),
                      DropdownMenuItem<DeckVisibility>(
                        value: DeckVisibility.unlisted,
                        child: Text('Nao listado (link)'),
                      ),
                      DropdownMenuItem<DeckVisibility>(
                        value: DeckVisibility.public,
                        child: Text('Publico na Comunidade'),
                      ),
                    ],
                    onChanged: (DeckVisibility? v) {
                      if (v != null) {
                        setModalState(() => visibility = v);
                      }
                    },
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
                    if (titleCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final ServiceLocator locator = ServiceLocator.instance;
                    await locator.deckRepository.createDeck(
                      userId: locator.activeUserId,
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      parentDeckId: parentDeckId,
                      visibility: visibility,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    await _loadDecks();
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _clonePublicDeck(Deck publicDeck) async {
    final ServiceLocator locator = ServiceLocator.instance;
    final String clonedId = await locator.deckRepository.clonePublicDeck(
      sourceDeckId: publicDeck.id,
      userId: locator.activeUserId,
      fallbackTitle: publicDeck.title,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Baralho "${publicDeck.title}" clonado!')),
    );
    context.go('/decks/$clonedId');
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              _showMarketplace ? 'Comunidade Flashi' : 'Hierarquia de Decks',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            CyberPrimaryButton(
              label: 'Novo Deck',
              icon: Icons.add_rounded,
              onPressed: () => _showCreateDeckDialog(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Segmented Toggle: Meus Decks vs Marketplace
        Row(
          children: <Widget>[
            Expanded(
              child: ChoiceChip(
                label: const Text('Meus Baralhos'),
                selected: !_showMarketplace,
                onSelected: (_) => setState(() => _showMarketplace = false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('Explorar Publicos'),
                selected: _showMarketplace,
                onSelected: (_) => setState(() => _showMarketplace = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_showMarketplace) ...<Widget>[
          TextField(
            controller: _searchController,
            onChanged: (_) => _loadDecks(),
            decoration: const InputDecoration(
              hintText: 'Pesquisar baralhos publicos da comunidade...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          ..._publicDecks.map(
            (Deck pub) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassBentoCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'PUBLIC DECK',
                            style: FlashiTypography.monoMetric(
                              color: colors.accentCyan,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pub.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (pub.description != null)
                            Text(
                              pub.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CyberPrimaryButton(
                      label: 'Clonar',
                      icon: Icons.copy_all_rounded,
                      onPressed: () => _clonePublicDeck(pub),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_myDecks.isEmpty)
          GlassBentoCard(
            child: Column(
              children: <Widget>[
                Icon(Icons.folder_open_rounded, size: 42, color: colors.textMuted),
                const SizedBox(height: 10),
                const Text('Voce ainda nao possui baralhos.'),
                const SizedBox(height: 12),
                CyberPrimaryButton(
                  label: 'Criar Primeiro Baralho',
                  icon: Icons.add_rounded,
                  onPressed: () => _showCreateDeckDialog(),
                ),
              ],
            ),
          )
        else
          ..._myDecks.map(
            (Deck deck) => Padding(
              padding: EdgeInsets.only(
                bottom: 10,
                left: deck.parentDeckId != null ? 20 : 0,
              ),
              child: GlassBentoCard(
                onTap: () => context.go('/decks/${deck.id}'),
                child: Row(
                  children: <Widget>[
                    Icon(
                      deck.parentDeckId != null
                          ? Icons.subdirectory_arrow_right_rounded
                          : Icons.layers_rounded,
                      color: colors.accentCyan,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            deck.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (deck.description != null &&
                              deck.description!.isNotEmpty)
                            Text(
                              deck.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Criar sub-baralho',
                      icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                      onPressed: () =>
                          _showCreateDeckDialog(parentDeckId: deck.id),
                    ),
                    IconButton(
                      tooltip: 'Estudar este deck',
                      icon: Icon(
                        Icons.play_circle_fill_rounded,
                        color: colors.accentCyan,
                      ),
                      onPressed: () => context.go('/study?deckId=${deck.id}'),
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

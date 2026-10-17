import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/repositories/search_repository.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Hybrid Semantic (pgvector + OpenAI `text-embedding-3-small`) and Full-Text
/// Search screen (`/search`).
///
/// Mirrors `src/app/search/page.tsx` from `app-flashi`.
class SemanticSearchScreen extends StatefulWidget {
  const SemanticSearchScreen({super.key});

  @override
  State<SemanticSearchScreen> createState() => _SemanticSearchScreenState();
}

class _SemanticSearchScreenState extends State<SemanticSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  List<SearchHit> _hits = const <SearchHit>[];
  bool _semanticEnabled = true;
  bool _searching = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _executeSearch() async {
    final String q = _queryController.text.trim();
    if (q.isEmpty) {
      setState(() => _hits = const <SearchHit>[]);
      return;
    }
    setState(() => _searching = true);
    final ServiceLocator locator = ServiceLocator.instance;
    final List<SearchHit> results = await locator.searchRepository.searchCards(
      userId: locator.activeUserId,
      query: q,
      semanticMode: _semanticEnabled,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _hits = results;
      _searching = false;
    });
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
                'Busca Semantica Hibrida',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Combina embeddings vetoriais (text-embedding-3-small) com Full-Text Search via Reciprocal Rank Fusion (RRF).',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _queryController,
          onSubmitted: (_) => _executeSearch(),
          onChanged: (_) => _executeSearch(),
          decoration: InputDecoration(
            hintText: 'Busque por conceito, sintoma ou palavra-chave...',
            prefixIcon: const Icon(Icons.manage_search_rounded),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: _executeSearch,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Modo Vetorial Semantico (pgvector + RRF)'),
          subtitle: Text(
            'Encontra cartoes pelo significado mesmo sem palavras identicas',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          value: _semanticEnabled,
          onChanged: (bool v) {
            setState(() => _semanticEnabled = v);
            _executeSearch();
          },
        ),
        const SizedBox(height: 12),
        if (_searching)
          const Center(child: CircularProgressIndicator())
        else if (_hits.isEmpty && _queryController.text.trim().isNotEmpty)
          GlassBentoCard(
            child: Text(
              'Nenhum cartao encontrado para "${_queryController.text}".',
              style: TextStyle(color: colors.textSecondary),
            ),
          )
        else
          ..._hits.map(
            (SearchHit hit) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassBentoCard(
                onTap: () => context.go('/decks/${hit.card.deckId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          hit.deckTitle ?? 'Deck Flashi',
                          style: FlashiTypography.monoMetric(
                            color: colors.accentCyan,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Score ${(hit.score * 100).toStringAsFixed(0)}%',
                          style: FlashiTypography.monoMetric(
                            color: colors.ratingGood,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hit.card.front,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hit.card.back,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
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

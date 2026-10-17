import '../../domain/models/flashcard.dart';
import '../local/app_database.dart';
import '../remote/edge_function_client.dart';
import '../remote/supabase_client_provider.dart';

/// Hybrid Semantic (pgvector + OpenAI `text-embedding-3-small`) and Full-Text
/// Search repository (`semantic-search` Edge Function + `hybrid_search_cards` RPC).
///
/// Mirrors `src/lib/services/search-service.ts` from `app-flashi`.
class SearchHit {
  const SearchHit({
    required this.card,
    required this.score,
    this.deckTitle,
  });

  final Flashcard card;
  final double score;
  final String? deckTitle;
}

class SearchRepository {
  SearchRepository({
    FlashiLocalDatabase? database,
    EdgeFunctionClient? edgeClient,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _edgeClient = edgeClient ?? EdgeFunctionClient.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final EdgeFunctionClient _edgeClient;
  final SupabaseClientProvider _supabaseProvider;

  /// Searches cards using `semantic-search` Edge Function when online or local
  /// full-text matching when offline.
  Future<List<SearchHit>> searchCards({
    required String userId,
    required String query,
    String? deckId,
    bool semanticMode = true,
  }) async {
    final String normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const <SearchHit>[];
    }

    if (semanticMode && _supabaseProvider.isAvailable) {
      try {
        final Map<String, dynamic> res = await _edgeClient.invoke(
          'semantic-search',
          body: <String, dynamic>{
            'query': normalizedQuery,
            if (deckId != null) 'deckId': deckId,
            'limit': 30,
          },
        );
        final List<dynamic> results =
            res['results'] as List<dynamic>? ?? const <dynamic>[];
        if (results.isNotEmpty) {
          return results
              .whereType<Map<String, dynamic>>()
              .map((Map<String, dynamic> item) {
                return SearchHit(
                  card: Flashcard.fromJson(item),
                  score: (item['similarity'] as num?)?.toDouble() ??
                      (item['rrf_score'] as num?)?.toDouble() ??
                      0.92,
                  deckTitle: item['deck_title']?.toString(),
                );
              })
              .toList(growable: false);
        }
      } catch (_) {
        // Fallback to local FTS search below
      }
    }

    final List<Map<String, dynamic>> localCards = await _database.queryTable(
      'cards',
      userId: userId,
      deckId: deckId,
    );
    final List<Map<String, dynamic>> localDecks =
        await _database.queryTable('decks', userId: userId);
    final Map<String, String> deckTitles = <String, String>{
      for (final Map<String, dynamic> d in localDecks)
        (d['id']?.toString() ?? ''): (d['title']?.toString() ?? ''),
    };

    final List<String> terms = normalizedQuery
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();

    final List<SearchHit> hits = <SearchHit>[];
    for (final Map<String, dynamic> row in localCards) {
      final String front = (row['front']?.toString() ?? '').toLowerCase();
      final String back = (row['back']?.toString() ?? '').toLowerCase();
      final String extra = (row['extra']?.toString() ?? '').toLowerCase();

      int matchedTerms = 0;
      for (final String term in terms) {
        if (front.contains(term) || back.contains(term) || extra.contains(term)) {
          matchedTerms++;
        }
      }
      if (matchedTerms > 0) {
        final double score = matchedTerms / terms.length;
        final Flashcard card = Flashcard.fromJson(row);
        hits.add(
          SearchHit(
            card: card,
            score: score,
            deckTitle: deckTitles[card.deckId],
          ),
        );
      }
    }

    hits.sort((SearchHit a, SearchHit b) => b.score.compareTo(a.score));
    return hits;
  }
}

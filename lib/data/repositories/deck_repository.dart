import '../../core/utils/crypto_utils.dart';
import '../../domain/models/deck.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for hierarchical decks (up to 5 nesting levels), public marketplace
/// browsing, and deck cloning.
///
/// Mirrors `src/lib/services/deck-service.ts` from `app-flashi`.
class DeckRepository {
  DeckRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  /// Lists all non-deleted decks for [userId], ordered by `position`.
  Future<List<Deck>> listDecks({required String userId}) async {
    final List<Map<String, dynamic>> localRows =
        await _database.queryTable('decks', userId: userId);

    if (localRows.isNotEmpty) {
      final List<Deck> decks = localRows.map(Deck.fromJson).toList()
        ..sort((Deck a, Deck b) => a.position.compareTo(b.position));
      return decks;
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteRows = await client
            .from('decks')
            .select('*')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .order('position', ascending: true);

        final List<Deck> decks = <Deck>[];
        for (final dynamic item in remoteRows) {
          if (item is Map<String, dynamic>) {
            await _database.upsertRow('decks', item);
            decks.add(Deck.fromJson(item));
          }
        }
        return decks;
      } catch (_) {}
    }

    return const <Deck>[];
  }

  /// Gets a single deck by [deckId].
  Future<Deck?> getDeck(String deckId) async {
    final Map<String, dynamic>? local =
        await _database.getRow('decks', deckId);
    if (local != null && local['deleted_at'] == null) {
      return Deck.fromJson(local);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final Map<String, dynamic>? remote = await client
            .from('decks')
            .select('*')
            .eq('id', deckId)
            .isFilter('deleted_at', null)
            .maybeSingle();
        if (remote != null) {
          await _database.upsertRow('decks', remote);
          return Deck.fromJson(remote);
        }
      } catch (_) {}
    }
    return null;
  }

  /// Creates a new deck (validating max depth <= 5 when [parentDeckId] is set).
  Future<Deck> createDeck({
    required String userId,
    required String title,
    String? description,
    String? parentDeckId,
    String color = '#00F2FE',
    String icon = 'layers',
    DeckVisibility visibility = DeckVisibility.private,
  }) async {
    if (parentDeckId != null && parentDeckId.isNotEmpty) {
      final int depth = await _computeParentDepth(parentDeckId);
      if (depth >= 5) {
        throw StateError('Profundidade maxima de 5 sub-baralhos atingida.');
      }
    }

    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final String id = CryptoUtils.generateUuidV4();
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'parent_deck_id': parentDeckId,
      'title': title.trim(),
      'description': description?.trim(),
      'color': color,
      'icon': icon,
      'is_archived': false,
      'visibility': visibility.value,
      'position': 0,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    await _database.upsertRow('decks', payload);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final Map<String, dynamic> inserted =
            await client.from('decks').insert(payload).select('*').single();
        await _database.upsertRow('decks', inserted);
        return Deck.fromJson(inserted);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'decks',
          action: 'insert',
          payload: payload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'decks',
        action: 'insert',
        payload: payload,
      );
    }

    return Deck.fromJson(payload);
  }

  /// Updates an existing deck.
  Future<Deck> updateDeck(Deck deck) async {
    final Deck updated = deck.copyWith(
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    final Map<String, dynamic> payload = updated.toJson();
    await _database.upsertRow('decks', payload);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.from('decks').update(payload).eq('id', deck.id);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'decks',
          action: 'update',
          payload: payload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'decks',
        action: 'update',
        payload: payload,
      );
    }
    return updated;
  }

  /// Soft-deletes a deck by setting `deleted_at`.
  Future<void> deleteDeck(String deckId) async {
    final Map<String, dynamic>? existing =
        await _database.getRow('decks', deckId);
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    if (existing != null) {
      existing['deleted_at'] = nowIso;
      existing['updated_at'] = nowIso;
      await _database.upsertRow('decks', existing);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client
            .from('decks')
            .update(<String, dynamic>{'deleted_at': nowIso})
            .eq('id', deckId);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'decks',
          action: 'update',
          payload: <String, dynamic>{
            'id': deckId,
            'deleted_at': nowIso,
          },
        );
      }
    }
  }

  /// Lists public decks for the Marketplace (`/explore`).
  Future<List<Deck>> listPublicDecks({String? searchQuery}) async {
    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        var query = client
            .from('decks')
            .select('*')
            .eq('visibility', 'public')
            .isFilter('deleted_at', null);
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          query = query.ilike('title', '%${searchQuery.trim()}%');
        }
        final List<dynamic> rows =
            await query.order('updated_at', ascending: false).limit(50);
        return rows
            .whereType<Map<String, dynamic>>()
            .map(Deck.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    // Offline fallback: return curated showcase public decks
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final List<Deck> fallback = <Deck>[
      Deck(
        id: 'public-deck-med',
        userId: 'community',
        title: 'Anatomia & Fisiologia Humana (FSRS-6)',
        description: 'Cartoes de alta retencao com oclusao de imagem e cloze.',
        color: '#00F2FE',
        icon: 'heart-pulse',
        isArchived: false,
        visibility: DeckVisibility.public,
        position: 0,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Deck(
        id: 'public-deck-en',
        userId: 'community',
        title: 'Advanced English Phrasal Verbs & Idioms',
        description: '500 expressoes essenciais para fluencia executiva.',
        color: '#8B5CF6',
        icon: 'globe',
        isArchived: false,
        visibility: DeckVisibility.public,
        position: 1,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Deck(
        id: 'public-deck-law',
        userId: 'community',
        title: 'Direito Constitucional Esquematizado',
        description: 'Jurisprudencia STF + Art. 5 ao 37 com revisao espacada.',
        color: '#10B981',
        icon: 'scale',
        isArchived: false,
        visibility: DeckVisibility.public,
        position: 2,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    ];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final String q = searchQuery.toLowerCase();
      return fallback
          .where(
            (Deck d) =>
                d.title.toLowerCase().contains(q) ||
                (d.description?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return fallback;
  }

  /// Clones a public deck into [userId]'s workspace via `clone_public_deck` RPC.
  Future<String> clonePublicDeck({
    required String sourceDeckId,
    required String userId,
    String? fallbackTitle,
  }) async {
    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final dynamic result = await client.rpc(
          'clone_public_deck',
          params: <String, dynamic>{
            'p_source_deck_id': sourceDeckId,
          },
        );
        if (result != null) {
          return result.toString();
        }
      } catch (_) {}
    }

    final Deck cloned = await createDeck(
      userId: userId,
      title: fallbackTitle ?? 'Deck Clonado',
      description: 'Clonado da comunidade Flashi.',
    );
    return cloned.id;
  }

  Future<int> _computeParentDepth(String parentId) async {
    int depth = 1;
    String? currentId = parentId;
    while (currentId != null && depth <= 6) {
      final Deck? parent = await getDeck(currentId);
      if (parent == null || parent.parentDeckId == null) {
        break;
      }
      depth++;
      currentId = parent.parentDeckId;
    }
    return depth;
  }
}

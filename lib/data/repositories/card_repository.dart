import '../../core/utils/crypto_utils.dart';
import '../../domain/models/flashcard.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for flashcards (`cards` table), suspension/burying, and deck card queries.
///
/// Mirrors `src/lib/services/card-service.ts` from `app-flashi`.
class CardRepository {
  CardRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  /// Lists all non-deleted cards in [deckId].
  Future<List<Flashcard>> listCardsByDeck({
    required String deckId,
    String? userId,
  }) async {
    final List<Map<String, dynamic>> localRows = await _database.queryTable(
      'cards',
      deckId: deckId,
      userId: userId,
    );
    if (localRows.isNotEmpty) {
      final List<Flashcard> cards = localRows.map(Flashcard.fromJson).toList()
        ..sort((Flashcard a, Flashcard b) => a.position.compareTo(b.position));
      return cards;
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteRows = await client
            .from('cards')
            .select('*')
            .eq('deck_id', deckId)
            .isFilter('deleted_at', null)
            .order('position', ascending: true);
        final List<Flashcard> cards = <Flashcard>[];
        for (final dynamic item in remoteRows) {
          if (item is Map<String, dynamic>) {
            await _database.upsertRow('cards', item);
            cards.add(Flashcard.fromJson(item));
          }
        }
        return cards;
      } catch (_) {}
    }

    return const <Flashcard>[];
  }

  Future<int> countAllCards({required String userId}) async {
    final List<Map<String, dynamic>> localRows =
        await _database.queryTable('cards', userId: userId);
    if (localRows.isNotEmpty) {
      return localRows.length;
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteRows = await client
            .from('cards')
            .select('id')
            .eq('user_id', userId)
            .isFilter('deleted_at', null);
        return remoteRows.length;
      } catch (_) {}
    }
    return 0;
  }

  Future<Flashcard> createBasicCard({
    required String userId,
    required String deckId,
    required String front,
    required String back,
    String? extra,
    String cardType = 'basic',
  }) async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final String cardId = CryptoUtils.generateUuidV4();
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': cardId,
      'deck_id': deckId,
      'user_id': userId,
      'card_ord': 0,
      'card_type': cardType,
      'front': front.trim(),
      'back': back.trim(),
      'extra': extra?.trim(),
      'field_values': <String, dynamic>{
        'front': front.trim(),
        'back': back.trim(),
        if (extra != null) 'extra': extra.trim(),
      },
      'is_suspended': false,
      'is_buried': false,
      'position': 0,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    await _database.upsertRow('cards', payload);
    await _database.upsertRow('card_learning_state', <String, dynamic>{
      'user_id': userId,
      'card_id': cardId,
      'state': 'new',
      'due_date': nowIso,
      'stability': 0.0,
      'difficulty': 0.0,
      'elapsed_days': 0,
      'scheduled_days': 0,
      'reps': 0,
      'lapses': 0,
      'updated_at': nowIso,
    });

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.from('cards').insert(payload);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'cards',
          action: 'insert',
          payload: payload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'cards',
        action: 'insert',
        payload: payload,
      );
    }

    return Flashcard.fromJson(payload);
  }

  Future<Flashcard> updateCard(Flashcard card) async {
    final Flashcard updated = card.copyWith(
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    final Map<String, dynamic> payload = updated.toJson();
    await _database.upsertRow('cards', payload);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.from('cards').update(payload).eq('id', card.id);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'cards',
          action: 'update',
          payload: payload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'cards',
        action: 'update',
        payload: payload,
      );
    }

    return updated;
  }

  Future<void> deleteCard(String cardId) async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic>? row = await _database.getRow('cards', cardId);
    if (row != null) {
      row['deleted_at'] = nowIso;
      await _database.upsertRow('cards', row);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client
            .from('cards')
            .update(<String, dynamic>{'deleted_at': nowIso})
            .eq('id', cardId);
      } catch (_) {}
    }
  }
}

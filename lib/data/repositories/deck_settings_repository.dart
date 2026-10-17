import '../../domain/models/deck.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for per-deck study settings overrides (`user_deck_settings`).
///
/// Mirrors `src/lib/services/deck-settings-service.ts` from `app-flashi`.
class DeckSettingsRepository {
  DeckSettingsRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  Future<DeckSettings> getDeckSettings({
    required String userId,
    required String deckId,
  }) async {
    final String key = '$userId:$deckId';
    final Map<String, dynamic>? local =
        await _database.getRow('user_deck_settings', key);
    if (local != null) {
      return DeckSettings.fromJson(local);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final Map<String, dynamic>? remote = await client
            .from('user_deck_settings')
            .select('*')
            .eq('user_id', userId)
            .eq('deck_id', deckId)
            .maybeSingle();
        if (remote != null) {
          await _database.upsertRow('user_deck_settings', remote);
          return DeckSettings.fromJson(remote);
        }
      } catch (_) {}
    }

    return DeckSettings(
      userId: userId,
      deckId: deckId,
    );
  }

  Future<DeckSettings> saveDeckSettings(DeckSettings settings) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      ...settings.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _database.upsertRow('user_deck_settings', payload);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.from('user_deck_settings').upsert(payload);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'user_deck_settings',
          action: 'update',
          payload: payload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'user_deck_settings',
        action: 'update',
        payload: payload,
      );
    }

    return settings;
  }
}

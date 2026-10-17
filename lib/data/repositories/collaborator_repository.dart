import '../../core/utils/crypto_utils.dart';
import '../../domain/models/deck.dart';
import '../local/app_database.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for deck collaborators (`viewer`, `editor`, `owner`) and invites.
///
/// Mirrors `src/lib/services/collaborator-service.ts` from `app-flashi`.
class CollaboratorRepository {
  CollaboratorRepository({
    FlashiLocalDatabase? database,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final SupabaseClientProvider _supabaseProvider;

  Future<List<DeckCollaborator>> listCollaborators(String deckId) async {
    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> rows = await client
            .from('deck_collaborators')
            .select('*')
            .eq('deck_id', deckId)
            .isFilter('deleted_at', null);
        return rows
            .whereType<Map<String, dynamic>>()
            .map(DeckCollaborator.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    final List<Map<String, dynamic>> localRows =
        await _database.queryTable('deck_collaborators', deckId: deckId);
    return localRows.map(DeckCollaborator.fromJson).toList(growable: false);
  }

  Future<DeckCollaborator> addCollaborator({
    required String deckId,
    required String userId,
    required String role,
  }) async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': CryptoUtils.generateUuidV4(),
      'deck_id': deckId,
      'user_id': userId,
      'role': role,
      'created_at': nowIso,
    };

    await _database.upsertRow('deck_collaborators', payload);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final Map<String, dynamic> remote = await client
            .from('deck_collaborators')
            .insert(payload)
            .select('*')
            .single();
        await _database.upsertRow('deck_collaborators', remote);
        return DeckCollaborator.fromJson(remote);
      } catch (_) {}
    }

    return DeckCollaborator.fromJson(payload);
  }

  Future<void> removeCollaborator(String collaboratorId) async {
    await _database.deleteRow('deck_collaborators', collaboratorId);
    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client
            .from('deck_collaborators')
            .delete()
            .eq('id', collaboratorId);
      } catch (_) {}
    }
  }
}

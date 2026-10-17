import '../../core/utils/crypto_utils.dart';
import '../../domain/models/flashcard.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for user tags (`tags` and `card_tags`).
///
/// Mirrors `src/lib/services/tag-service.ts` from `app-flashi`.
class TagRepository {
  TagRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  Future<List<Tag>> listTags({required String userId}) async {
    final List<Map<String, dynamic>> localRows =
        await _database.queryTable('tags', userId: userId);
    if (localRows.isNotEmpty) {
      return localRows.map(Tag.fromJson).toList(growable: false);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteRows = await client
            .from('tags')
            .select('*')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .order('name', ascending: true);
        return remoteRows
            .whereType<Map<String, dynamic>>()
            .map(Tag.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    return const <Tag>[];
  }

  Future<Tag> createTag({
    required String userId,
    required String name,
    String color = '#8B5CF6',
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': CryptoUtils.generateUuidV4(),
      'user_id': userId,
      'name': name.trim().toLowerCase(),
      'color': color,
    };
    await _database.upsertRow('tags', payload);
    await _outboxQueue.enqueueMutation(
      tableName: 'tags',
      action: 'insert',
      payload: payload,
    );
    return Tag.fromJson(payload);
  }
}

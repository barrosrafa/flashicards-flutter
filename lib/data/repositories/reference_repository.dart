import '../../core/utils/crypto_utils.dart';
import '../../domain/models/note.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';

/// Repository for bidirectional note links (`note_references`).
///
/// Mirrors `src/lib/services/reference-service.ts` from `app-flashi`.
class ReferenceRepository {
  ReferenceRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue();

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;

  Future<List<NoteReference>> listReferences({required String userId}) async {
    final List<Map<String, dynamic>> rows =
        await _database.queryTable('note_references', userId: userId);
    return rows.map(NoteReference.fromJson).toList(growable: false);
  }

  Future<NoteReference> linkNotes({
    required String userId,
    required String sourceNoteId,
    required String targetNoteId,
    String referenceType = 'related',
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': CryptoUtils.generateUuidV4(),
      'user_id': userId,
      'source_note_id': sourceNoteId,
      'target_note_id': targetNoteId,
      'reference_type': referenceType,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _database.upsertRow('note_references', payload);
    await _outboxQueue.enqueueMutation(
      tableName: 'note_references',
      action: 'insert',
      payload: payload,
    );
    return NoteReference.fromJson(payload);
  }
}

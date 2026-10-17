import '../../core/utils/crypto_utils.dart';
import '../../domain/models/note.dart';
import '../../domain/services/note_card_fields_deriver.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for notes, cloze deletions, and transactional note+card creation.
///
/// Mirrors `src/lib/services/note-service.ts` from `app-flashi`:
/// - Calls `mcp_create_note` RPC to atomically create note, cards, and `card_learning_state`.
/// - Calls `update_note_and_cards_v2` RPC when updating a note.
class NoteRepository {
  NoteRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  Future<Note> createNote({
    required String userId,
    required NoteInput input,
  }) async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final String noteId = CryptoUtils.generateUuidV4();
    final List<DerivedCardDefinition> derivedCards =
        NoteCardFieldsDeriver.deriveCards(input);
    final String combinedText = input.fieldValues.values.join(' ');
    final String checksum = CryptoUtils.computeNoteChecksum(combinedText);

    final Map<String, dynamic> noteRow = <String, dynamic>{
      'id': noteId,
      'user_id': userId,
      'deck_id': input.deckId,
      'template_id': input.templateId,
      'model_kind': input.modelKind,
      'field_values': input.fieldValues,
      'source_type': input.sourceType ?? 'manual',
      'source_metadata': input.sourceMetadata ?? <String, dynamic>{},
      'checksum': checksum,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    await _database.upsertRow('notes', noteRow);

    // Create local cards and initial FSRS learning states so getDueCards sees them immediately
    for (final DerivedCardDefinition def in derivedCards) {
      final String cardId = CryptoUtils.generateUuidV4();
      await _database.upsertRow('cards', <String, dynamic>{
        'id': cardId,
        'deck_id': input.deckId,
        'user_id': userId,
        'note_id': noteId,
        'template_id': input.templateId,
        'card_ord': def.ord,
        'card_type': def.cardType,
        'front': def.front,
        'back': def.back,
        'extra': def.extra,
        'field_values': input.fieldValues,
        'is_suspended': false,
        'is_buried': false,
        'position': def.ord,
        'created_at': nowIso,
        'updated_at': nowIso,
      });

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
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.rpc(
          'mcp_create_note',
          params: <String, dynamic>{
            'p_deck_id': input.deckId,
            'p_model_kind': input.modelKind,
            'p_field_values': input.fieldValues,
            'p_cards': derivedCards
                .map((DerivedCardDefinition c) => c.toJson())
                .toList(),
            'p_template_id': input.templateId,
          },
        );
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'notes',
          action: 'insert',
          payload: noteRow,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'notes',
        action: 'insert',
        payload: noteRow,
      );
    }

    return Note.fromJson(noteRow);
  }

  Future<Note> updateNote({
    required String noteId,
    required String userId,
    required NoteInput input,
  }) async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final List<DerivedCardDefinition> derivedCards =
        NoteCardFieldsDeriver.deriveCards(input);

    final Map<String, dynamic> updatedRow = <String, dynamic>{
      'id': noteId,
      'user_id': userId,
      'deck_id': input.deckId,
      'template_id': input.templateId,
      'model_kind': input.modelKind,
      'field_values': input.fieldValues,
      'updated_at': nowIso,
      'created_at': nowIso,
    };
    await _database.upsertRow('notes', updatedRow);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.rpc(
          'update_note_and_cards_v2',
          params: <String, dynamic>{
            'p_note_id': noteId,
            'p_field_values': input.fieldValues,
            'p_cards': derivedCards
                .map((DerivedCardDefinition c) => c.toJson())
                .toList(),
          },
        );
      } catch (_) {}
    }

    return Note.fromJson(updatedRow);
  }
}

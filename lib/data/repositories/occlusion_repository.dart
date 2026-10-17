import 'dart:typed_data';

import '../../core/constants/storage_buckets.dart';
import '../../core/utils/crypto_utils.dart';
import '../../domain/models/occlusion_mask.dart';
import '../local/app_database.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for staging image occlusion assets and creating 1-card-per-mask
/// image occlusion notes (`stage_image_occlusion_asset` & `create_image_occlusion_note`).
///
/// Mirrors `src/lib/services/occlusion-service.ts` from `app-flashi`.
class OcclusionRepository {
  OcclusionRepository({
    FlashiLocalDatabase? database,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final SupabaseClientProvider _supabaseProvider;

  Future<OcclusionCreationResult> createImageOcclusionNote({
    required String userId,
    required String deckId,
    required String fileName,
    required String mimeType,
    required Uint8List imageBytes,
    required List<OcclusionMask> masks,
    String? title,
    String? extraNotes,
  }) async {
    if (masks.isEmpty) {
      throw ArgumentError('Adicione pelo menos uma mascara de oclusao.');
    }

    final String assetId = CryptoUtils.generateUuidV4();
    final String noteId = CryptoUtils.generateUuidV4();
    final String ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'png';
    final String storagePath =
        '$userId/occlusion/$assetId.$ext';
    final String nowIso = DateTime.now().toUtc().toIso8601String();

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.storage.from(StorageBuckets.cardMedia).uploadBinary(
              storagePath,
              imageBytes,
            );
        await client.rpc(
          'stage_image_occlusion_asset',
          params: <String, dynamic>{
            'p_storage_path': storagePath,
            'p_file_name': fileName,
            'p_mime_type': mimeType,
            'p_size_bytes': imageBytes.lengthInBytes,
          },
        );
        final dynamic rpcResult = await client.rpc(
          'create_image_occlusion_note',
          params: <String, dynamic>{
            'p_deck_id': deckId,
            'p_storage_path': storagePath,
            'p_masks': masks.map((OcclusionMask m) => m.toJson()).toList(),
            'p_title': title ?? fileName,
            'p_extra': extraNotes,
          },
        );
        if (rpcResult is Map<String, dynamic>) {
          return OcclusionCreationResult.fromJson(rpcResult);
        }
      } catch (_) {}
    }

    // Local persistence for immediate offline study
    final List<String> cardIds = <String>[];
    await _database.upsertRow('notes', <String, dynamic>{
      'id': noteId,
      'user_id': userId,
      'deck_id': deckId,
      'model_kind': 'image_occlusion',
      'field_values': <String, dynamic>{
        'title': title ?? fileName,
        'storage_path': storagePath,
        if (extraNotes != null) 'extra': extraNotes,
      },
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    for (int i = 0; i < masks.length; i++) {
      final OcclusionMask mask = masks[i];
      final String cardId = CryptoUtils.generateUuidV4();
      cardIds.add(cardId);

      await _database.upsertRow('note_image_occlusion_boxes', <String, dynamic>{
        'id': mask.id,
        'note_id': noteId,
        'user_id': userId,
        'box_index': i + 1,
        'x_pct': mask.x,
        'y_pct': mask.y,
        'width_pct': mask.width,
        'height_pct': mask.height,
        'label': mask.label,
        'created_at': nowIso,
      });

      await _database.upsertRow('cards', <String, dynamic>{
        'id': cardId,
        'deck_id': deckId,
        'user_id': userId,
        'note_id': noteId,
        'card_ord': i,
        'card_type': 'image_occlusion',
        'front':
            '[IMAGE_OCCLUSION:${title ?? fileName} | Mascara #${i + 1} (${mask.label ?? "Oculto"})]',
        'back':
            'Mascara #${i + 1}: ${mask.label ?? "Regiao revelada"}${extraNotes != null && extraNotes.isNotEmpty ? "\n\n$extraNotes" : ""}',
        'extra': extraNotes,
        'field_values': <String, dynamic>{
          'storage_path': storagePath,
          'active_mask_id': mask.id,
          'masks': masks.map((OcclusionMask m) => m.toJson()).toList(),
        },
        'is_suspended': false,
        'is_buried': false,
        'position': i,
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

    return OcclusionCreationResult(
      noteId: noteId,
      cardIds: cardIds,
    );
  }
}

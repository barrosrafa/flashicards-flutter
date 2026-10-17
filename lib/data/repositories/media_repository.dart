import 'dart:typed_data';

import '../../core/constants/storage_buckets.dart';
import '../../core/utils/crypto_utils.dart';
import '../../domain/models/flashcard.dart';
import '../local/app_database.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for card media uploads (`card-media` private bucket), signed URL
/// caching, and storage quota validation.
///
/// Mirrors `src/lib/services/media-service.ts` from `app-flashi`.
class MediaRepository {
  MediaRepository({
    FlashiLocalDatabase? database,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final SupabaseClientProvider _supabaseProvider;

  final Map<String, ({String url, DateTime expiresAt})> _signedUrlCache =
      <String, ({String url, DateTime expiresAt})>{};

  Future<List<CardMedia>> listMedia({required String userId}) async {
    final List<Map<String, dynamic>> localRows =
        await _database.queryTable('card_media', userId: userId);
    if (localRows.isNotEmpty) {
      return localRows.map(CardMedia.fromJson).toList(growable: false);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteRows = await client
            .from('card_media')
            .select('*')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);
        return remoteRows
            .whereType<Map<String, dynamic>>()
            .map(CardMedia.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    return const <CardMedia>[];
  }

  /// Uploads a media file to `{userId}/{cardId}/{uuid}.{ext}` inside `card-media`.
  Future<CardMedia> uploadCardMedia({
    required String userId,
    required String cardId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    String fieldSide = 'front',
  }) async {
    if (!StorageBuckets.allowedCardMediaMimeTypes.contains(mimeType)) {
      throw ArgumentError('Tipo de arquivo nao suportado: $mimeType');
    }
    if (bytes.lengthInBytes > StorageBuckets.cardMediaMaxFileBytes) {
      throw ArgumentError('Arquivo excede o limite de 10 MB.');
    }

    final String mediaId = CryptoUtils.generateUuidV4();
    final String ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'bin';
    final String storagePath =
        StorageBuckets.buildCardMediaPath(userId, cardId, '$mediaId.$ext');
    final String nowIso = DateTime.now().toUtc().toIso8601String();

    final Map<String, dynamic> row = <String, dynamic>{
      'id': mediaId,
      'card_id': cardId,
      'user_id': userId,
      'storage_path': storagePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': bytes.lengthInBytes,
      'field_side': fieldSide,
      'created_at': nowIso,
    };

    await _database.upsertRow('card_media', row);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.storage.from(StorageBuckets.cardMedia).uploadBinary(
              storagePath,
              bytes,
            );
        await client.from('card_media').insert(row);
      } catch (_) {}
    }

    return CardMedia.fromJson(row);
  }

  /// Resolves a short-lived signed URL for [storagePath], caching it in memory.
  Future<String?> getSignedUrl(String storagePath) async {
    final DateTime now = DateTime.now();
    final cached = _signedUrlCache[storagePath];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.url;
    }

    final client = _supabaseProvider.client;
    if (client == null) {
      return null;
    }

    try {
      final String signed = await client.storage
          .from(StorageBuckets.cardMedia)
          .createSignedUrl(
            storagePath,
            StorageBuckets.signedUrlExpirySeconds,
          );
      _signedUrlCache[storagePath] = (
        url: signed,
        expiresAt: now.add(
          const Duration(seconds: StorageBuckets.signedUrlExpirySeconds - 60),
        ),
      );
      return signed;
    } catch (_) {
      return null;
    }
  }
}

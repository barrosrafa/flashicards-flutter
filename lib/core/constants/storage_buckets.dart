/// Constantes de buckets e limites de Storage verificados contra o backend Flashi.
class StorageBuckets {
  const StorageBuckets._();

  /// Bucket privado de mídias de cartões e assets staged de oclusão.
  static const String cardMedia = 'card-media';

  /// Bucket privado para pacotes `.apkg` do Anki (nunca `transfers`).
  static const String ankiTransfers = 'anki-transfers';

  /// Bucket privado para PDFs de ingestão IA e arquivos de importação de decks.
  static const String importMedia = 'import-media';

  /// Limites verificados no contrato do backend.
  static const int maxCardMediaBytes = 25 * 1024 * 1024; // 25 MiB
  static const int maxAnkiApkgBytes = 50 * 1024 * 1024; // 50 MiB
  static const int maxImportDeckBytes = 15 * 1024 * 1024; // 15 MiB
  static const int userTotalQuotaBytes = 250 * 1024 * 1024; // 250 MiB
  static const int signedUrlTtlSeconds = 30 * 60; // 30 minutos
  static const int signedUrlRenewBeforeSeconds = 60; // renova faltando 60s

  static const int cardMediaMaxFileBytes = maxCardMediaBytes;
  static const int ankiTransferMaxFileBytes = maxAnkiApkgBytes;
  static const int signedUrlExpirySeconds = signedUrlTtlSeconds;

  static const List<String> allowedMediaMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/avif',
    'image/svg+xml',
    'audio/mpeg',
    'audio/ogg',
    'audio/wav',
    'audio/webm',
    'audio/mp4',
    'video/mp4',
    'video/webm',
    'video/quicktime',
  ];

  static List<String> get allowedCardMediaMimeTypes => allowedMediaMimeTypes;

  static List<String> get allowedOcclusionImageMimeTypes => allowedMediaMimeTypes
      .where((mime) => mime.startsWith('image/'))
      .toList(growable: false);

  static String sanitizeFileName(String raw) {
    return raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  static String buildCardMediaPath(
    String userId,
    String cardId,
    String fileName,
  ) {
    return '$userId/$cardId/${sanitizeFileName(fileName)}';
  }

  static String buildAnkiTransferPath(
    String userId,
    String jobId,
    String fileName,
  ) {
    return '$userId/$jobId/${sanitizeFileName(fileName)}';
  }
}

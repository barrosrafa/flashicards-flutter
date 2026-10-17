/// Anki `.apkg` / `.colpkg` transfer models.
///
/// Mirrors `src/lib/services/anki-transfer-service.ts` from `app-flashi`.
class AnkiImportResult {
  const AnkiImportResult({
    required this.jobId,
    required this.status,
    required this.decksCreated,
    required this.notesImported,
    required this.cardsImported,
    required this.reviewsImported,
    required this.mediaUploaded,
  });

  final String jobId;
  final String status;
  final int decksCreated;
  final int notesImported;
  final int cardsImported;
  final int reviewsImported;
  final int mediaUploaded;

  factory AnkiImportResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> stats =
        (json['stats'] as Map<String, dynamic>?) ?? json;
    return AnkiImportResult(
      jobId: json['jobId']?.toString() ?? json['job_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'completed',
      decksCreated: (stats['decksCreated'] as num?)?.toInt() ??
          (stats['decks_created'] as num?)?.toInt() ??
          0,
      notesImported: (stats['notesImported'] as num?)?.toInt() ??
          (stats['notes_imported'] as num?)?.toInt() ??
          0,
      cardsImported: (stats['cardsImported'] as num?)?.toInt() ??
          (stats['cards_imported'] as num?)?.toInt() ??
          0,
      reviewsImported: (stats['reviewsImported'] as num?)?.toInt() ??
          (stats['reviews_imported'] as num?)?.toInt() ??
          0,
      mediaUploaded: (stats['mediaUploaded'] as num?)?.toInt() ??
          (stats['media_uploaded'] as num?)?.toInt() ??
          0,
    );
  }
}

/// Result returned when exporting a deck or collection to `.apkg` / `.colpkg`.
class AnkiExportResult {
  const AnkiExportResult({
    required this.jobId,
    required this.status,
    required this.downloadUrl,
    required this.fileName,
    required this.decksExported,
    required this.notesExported,
    required this.cardsExported,
    required this.reviewsExported,
    required this.mediaIncluded,
  });

  final String jobId;
  final String status;
  final String downloadUrl;
  final String fileName;
  final int decksExported;
  final int notesExported;
  final int cardsExported;
  final int reviewsExported;
  final int mediaIncluded;

  factory AnkiExportResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> stats =
        (json['stats'] as Map<String, dynamic>?) ?? json;
    return AnkiExportResult(
      jobId: json['jobId']?.toString() ?? json['job_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'completed',
      downloadUrl:
          json['downloadUrl']?.toString() ?? json['download_url']?.toString() ?? '',
      fileName: json['fileName']?.toString() ??
          json['file_name']?.toString() ??
          'flashi-export.apkg',
      decksExported: (stats['decksExported'] as num?)?.toInt() ?? 0,
      notesExported: (stats['notesExported'] as num?)?.toInt() ?? 0,
      cardsExported: (stats['cardsExported'] as num?)?.toInt() ?? 0,
      reviewsExported: (stats['reviewsExported'] as num?)?.toInt() ?? 0,
      mediaIncluded: (stats['mediaIncluded'] as num?)?.toInt() ?? 0,
    );
  }
}

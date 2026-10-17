/// AI Document Ingestion and structured deck import models.
///
/// Mirrors `src/lib/services/ingest-service.ts` and `import-service.ts` from `app-flashi`.
enum IngestionSourceType {
  pdf('pdf'),
  youtube('youtube'),
  webpage('webpage'),
  markdown('markdown'),
  text('text'),
  audio('audio');

  const IngestionSourceType(this.value);
  final String value;

  static IngestionSourceType fromString(String? raw) {
    return IngestionSourceType.values.firstWhere(
      (IngestionSourceType t) => t.value == raw,
      orElse: () => IngestionSourceType.text,
    );
  }
}

/// AI ingestion job record from `ai_ingestion_jobs`.
class IngestJob {
  const IngestJob({
    required this.id,
    required this.sourceType,
    required this.status,
    required this.cardsGeneratedCount,
    required this.createdAt,
    this.deckId,
    this.sourceUrl,
    this.errorMessage,
    this.completedAt,
  });

  final String id;
  final String? deckId;
  final IngestionSourceType sourceType;
  final String? sourceUrl;
  final String status;
  final int cardsGeneratedCount;
  final String? errorMessage;
  final String createdAt;
  final String? completedAt;

  bool get isTerminal => status == 'completed' || status == 'failed';

  factory IngestJob.fromJson(Map<String, dynamic> json) {
    return IngestJob(
      id: json['id']?.toString() ?? '',
      deckId: json['deck_id']?.toString(),
      sourceType: IngestionSourceType.fromString(json['source_type']?.toString()),
      sourceUrl: json['source_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      cardsGeneratedCount:
          (json['cards_generated_count'] as num?)?.toInt() ?? 0,
      errorMessage: json['error_message']?.toString(),
      createdAt:
          json['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      completedAt: json['completed_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'deck_id': deckId,
      'source_type': sourceType.value,
      'source_url': sourceUrl,
      'status': status,
      'cards_generated_count': cardsGeneratedCount,
      'error_message': errorMessage,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }
}

/// Supported file import formats for `import-deck`.
enum ImportFormat {
  csv('csv'),
  tsv('tsv'),
  txt('txt'),
  json('json'),
  markdown('markdown'),
  xml('xml');

  const ImportFormat(this.value);
  final String value;

  static ImportFormat fromString(String? raw) {
    return ImportFormat.values.firstWhere(
      (ImportFormat f) => f.value == raw,
      orElse: () => ImportFormat.csv,
    );
  }
}

/// Response from `import-deck` Edge Function.
class ImportDeckResult {
  const ImportDeckResult({
    required this.jobId,
    required this.deckId,
    required this.importedCount,
    required this.failedCount,
  });

  final String jobId;
  final String deckId;
  final int importedCount;
  final int failedCount;

  factory ImportDeckResult.fromJson(Map<String, dynamic> json) {
    return ImportDeckResult(
      jobId: json['jobId']?.toString() ?? json['job_id']?.toString() ?? '',
      deckId: json['deckId']?.toString() ?? json['deck_id']?.toString() ?? '',
      importedCount:
          (json['importedCount'] as num?)?.toInt() ??
          (json['imported_count'] as num?)?.toInt() ??
          0,
      failedCount:
          (json['failedCount'] as num?)?.toInt() ??
          (json['failed_count'] as num?)?.toInt() ??
          0,
    );
  }
}

/// Record from `import_jobs` table.
class ImportJob {
  const ImportJob({
    required this.id,
    required this.deckId,
    required this.format,
    required this.status,
    required this.totalRows,
    required this.importedRows,
    required this.failedRows,
    required this.errorLog,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String deckId;
  final ImportFormat format;
  final String status;
  final int totalRows;
  final int importedRows;
  final int failedRows;
  final List<Map<String, dynamic>> errorLog;
  final String createdAt;
  final String? completedAt;

  factory ImportJob.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawErrors =
        json['error_log'] as List<dynamic>? ?? const <dynamic>[];
    return ImportJob(
      id: json['id']?.toString() ?? '',
      deckId: json['deck_id']?.toString() ?? '',
      format: ImportFormat.fromString(json['format']?.toString()),
      status: json['status']?.toString() ?? 'pending',
      totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
      importedRows: (json['imported_rows'] as num?)?.toInt() ?? 0,
      failedRows: (json['failed_rows'] as num?)?.toInt() ?? 0,
      errorLog: rawErrors.whereType<Map<String, dynamic>>().toList(growable: false),
      createdAt:
          json['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      completedAt: json['completed_at']?.toString(),
    );
  }
}

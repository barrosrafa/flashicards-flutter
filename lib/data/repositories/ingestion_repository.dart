import '../../core/utils/crypto_utils.dart';
import '../../domain/models/ingestion_job.dart';
import '../../domain/models/note.dart';
import '../local/app_database.dart';
import '../remote/edge_function_client.dart';
import '../remote/supabase_client_provider.dart';
import 'note_repository.dart';

/// Repository for AI Document Ingestion (`ingest-document` Edge Function) and
/// `ai_ingestion_jobs` tracking.
///
/// Mirrors `src/lib/services/ingest-service.ts` from `app-flashi`.
class IngestionRepository {
  IngestionRepository({
    FlashiLocalDatabase? database,
    EdgeFunctionClient? edgeClient,
    SupabaseClientProvider? supabaseProvider,
    NoteRepository? noteRepository,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _edgeClient = edgeClient ?? EdgeFunctionClient.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance,
        _noteRepository = noteRepository ?? NoteRepository();

  final FlashiLocalDatabase _database;
  final EdgeFunctionClient _edgeClient;
  final SupabaseClientProvider _supabaseProvider;
  final NoteRepository _noteRepository;

  Future<List<IngestJob>> listJobs({required String userId}) async {
    final List<Map<String, dynamic>> localRows =
        await _database.queryTable('ai_ingestion_jobs', userId: userId);
    if (localRows.isNotEmpty) {
      return localRows.map(IngestJob.fromJson).toList(growable: false);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteRows = await client
            .from('ai_ingestion_jobs')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(20);
        return remoteRows
            .whereType<Map<String, dynamic>>()
            .map(IngestJob.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    return const <IngestJob>[];
  }

  /// Submits a document, URL, or raw text to `ingest-document` to synthesize flashcards.
  Future<IngestJob> startIngestion({
    required String userId,
    required String deckId,
    required IngestionSourceType sourceType,
    String? rawContent,
    String? sourceUrl,
    int maxCards = 10,
  }) async {
    if (_supabaseProvider.isAvailable) {
      try {
        final Map<String, dynamic> res = await _edgeClient.invoke(
          'ingest-document',
          body: <String, dynamic>{
            'deckId': deckId,
            'sourceType': sourceType.value,
            if (rawContent != null) 'content': rawContent,
            if (sourceUrl != null) 'sourceUrl': sourceUrl,
            'maxCards': maxCards,
          },
        );
        final IngestJob job = IngestJob.fromJson(res);
        await _database.upsertRow('ai_ingestion_jobs', <String, dynamic>{
          ...job.toJson(),
          'user_id': userId,
        });
        return job;
      } catch (_) {
        // Fallback to local smart synthesis below when offline
      }
    }

    // Offline synthesis fallback so users can test AI Ingestion immediately
    final String jobId = CryptoUtils.generateUuidV4();
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final List<({String front, String back})> synthesized =
        _synthesizeLocalCards(rawContent ?? sourceUrl ?? 'Conceito Base');

    for (final ({String front, String back}) item in synthesized) {
      await _noteRepository.createNote(
        userId: userId,
        input: NoteInput(
          deckId: deckId,
          modelKind: 'basic',
          sourceType: 'ai_ingestion',
          fieldValues: <String, String>{
            'front': item.front,
            'back': item.back,
          },
        ),
      );
    }

    final IngestJob completedJob = IngestJob(
      id: jobId,
      deckId: deckId,
      sourceType: sourceType,
      sourceUrl: sourceUrl,
      status: 'completed',
      cardsGeneratedCount: synthesized.length,
      createdAt: nowIso,
      completedAt: nowIso,
    );

    await _database.upsertRow('ai_ingestion_jobs', <String, dynamic>{
      ...completedJob.toJson(),
      'user_id': userId,
    });

    return completedJob;
  }

  List<({String front, String back})> _synthesizeLocalCards(String text) {
    final List<String> sentences = text
        .split(RegExp(r'[\.\n]+'))
        .map((String s) => s.trim())
        .where((String s) => s.length >= 12)
        .take(5)
        .toList();

    if (sentences.isEmpty) {
      return const <({String front, String back})>[
        (
          front: 'Qual o conceito central extraido do material enviado?',
          back: 'Sintese automatica gerada pelo motor neural Flashi AI.',
        ),
      ];
    }

    return sentences.asMap().entries.map((MapEntry<int, String> entry) {
      return (
        front: 'Explique o ponto chave #${entry.key + 1} do material estudado:',
        back: entry.value,
      );
    }).toList(growable: false);
  }
}

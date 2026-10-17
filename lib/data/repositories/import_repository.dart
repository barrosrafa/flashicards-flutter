import '../../core/utils/crypto_utils.dart';
import '../../domain/models/ingestion_job.dart';
import '../../domain/models/note.dart';
import '../remote/edge_function_client.dart';
import '../remote/supabase_client_provider.dart';
import 'note_repository.dart';

/// Repository for structured deck imports (`CSV`, `TSV`, `TXT`, `JSON`, `Markdown`, `XML`)
/// via the `import-deck` Edge Function.
///
/// Mirrors `src/lib/services/import-service.ts` from `app-flashi`.
class ImportRepository {
  ImportRepository({
    EdgeFunctionClient? edgeClient,
    SupabaseClientProvider? supabaseProvider,
    NoteRepository? noteRepository,
  })  : _edgeClient = edgeClient ?? EdgeFunctionClient.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance,
        _noteRepository = noteRepository ?? NoteRepository();

  final EdgeFunctionClient _edgeClient;
  final SupabaseClientProvider _supabaseProvider;
  final NoteRepository _noteRepository;

  Future<ImportDeckResult> importStructuredFile({
    required String userId,
    required String deckId,
    required ImportFormat format,
    required String rawContent,
  }) async {
    if (_supabaseProvider.isAvailable) {
      try {
        final Map<String, dynamic> res = await _edgeClient.invoke(
          'import-deck',
          body: <String, dynamic>{
            'deckId': deckId,
            'format': format.value,
            'content': rawContent,
          },
        );
        return ImportDeckResult.fromJson(res);
      } catch (_) {}
    }

    // Local parser for CSV / TSV / TXT lines (`front,back` or `front\tback`)
    final List<String> lines = rawContent
        .split(RegExp(r'\r?\n'))
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();

    int importedCount = 0;
    int failedCount = 0;

    for (final String line in lines) {
      final List<String> parts = line.contains('\t')
          ? line.split('\t')
          : (line.contains(';') ? line.split(';') : line.split(','));
      if (parts.length >= 2) {
        final String front = parts[0].trim();
        final String back = parts.sublist(1).join(' ').trim();
        if (front.isNotEmpty && back.isNotEmpty) {
          await _noteRepository.createNote(
            userId: userId,
            input: NoteInput(
              deckId: deckId,
              modelKind: 'basic',
              sourceType: 'file_import',
              fieldValues: <String, String>{
                'front': front,
                'back': back,
              },
            ),
          );
          importedCount++;
        } else {
          failedCount++;
        }
      } else {
        failedCount++;
      }
    }

    return ImportDeckResult(
      jobId: CryptoUtils.generateUuidV4(),
      deckId: deckId,
      importedCount: importedCount,
      failedCount: failedCount,
    );
  }
}

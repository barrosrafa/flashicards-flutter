import '../../core/utils/crypto_utils.dart';
import '../../domain/models/deck_exam.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for Exam Mode targets (`deck_exams`) and dynamic FSRS interval
/// boost multiplier computation ($1.0 \le m \le 2.5$).
///
/// Mirrors `src/lib/services/exam-service.ts` from `app-flashi`.
class ExamRepository {
  ExamRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  Future<List<DeckExam>> listActiveExams({
    required String userId,
    String? deckId,
  }) async {
    final List<Map<String, dynamic>> localRows = await _database.queryTable(
      'deck_exams',
      userId: userId,
      deckId: deckId,
    );
    if (localRows.isNotEmpty) {
      return localRows
          .map(DeckExam.fromJson)
          .where((DeckExam e) => e.status == ExamStatus.active)
          .toList(growable: false);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        var query = client
            .from('deck_exams')
            .select('*')
            .eq('user_id', userId)
            .eq('status', 'active')
            .isFilter('deleted_at', null);
        if (deckId != null) {
          query = query.eq('deck_id', deckId);
        }
        final List<dynamic> rows =
            await query.order('exam_date', ascending: true);
        return rows
            .whereType<Map<String, dynamic>>()
            .map(DeckExam.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    return const <DeckExam>[];
  }

  Future<DeckExam> createExam({
    required String userId,
    required String deckId,
    required String title,
    required DateTime examDate,
    double targetRetention = 0.95,
    ExamPriority priority = ExamPriority.high,
  }) async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final String dateStr = examDate.toIso8601String().split('T').first;
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': CryptoUtils.generateUuidV4(),
      'deck_id': deckId,
      'user_id': userId,
      'title': title.trim(),
      'exam_date': dateStr,
      'target_retention': targetRetention.clamp(0.7, 0.99),
      'priority': priority.value,
      'status': ExamStatus.active.value,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    await _database.upsertRow('deck_exams', payload);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.from('deck_exams').insert(payload);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'deck_exams',
          action: 'insert',
          payload: payload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'deck_exams',
        action: 'insert',
        payload: payload,
      );
    }

    return DeckExam.fromJson(payload);
  }

  Future<void> markExamCompleted(String examId) async {
    final Map<String, dynamic>? row =
        await _database.getRow('deck_exams', examId);
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    if (row != null) {
      row['status'] = ExamStatus.completed.value;
      row['updated_at'] = nowIso;
      await _database.upsertRow('deck_exams', row);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client
            .from('deck_exams')
            .update(<String, dynamic>{
              'status': ExamStatus.completed.value,
              'updated_at': nowIso,
            })
            .eq('id', examId);
      } catch (_) {}
    }
  }
}

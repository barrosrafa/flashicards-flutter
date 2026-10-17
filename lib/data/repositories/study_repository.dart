import '../../core/utils/crypto_utils.dart';
import '../../domain/models/due_card.dart';
import '../../domain/models/review_result.dart';
import '../../domain/services/fsrs_scheduler_adapter.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/edge_function_client.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for FSRS-6 spaced repetition study sessions, local offline scheduling,
/// and `review-card` Edge Function synchronization.
///
/// Mirrors `src/lib/services/study-service.ts` from `app-flashi`:
/// - Uses Dart `fsrs` package locally for instant (< 16ms) optimistic scheduling.
/// - Applies Exam Mode boost multiplier ($1.0 \le m \le 2.5$) when an active exam exists.
/// - Enqueues reviews in `OutboxQueue` with UUIDv4 `idempotency_key` if offline.
class StudyRepository {
  StudyRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    EdgeFunctionClient? edgeClient,
    SupabaseClientProvider? supabaseProvider,
    FsrsSchedulerAdapter? fsrsScheduler,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _edgeClient = edgeClient ?? EdgeFunctionClient.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance,
        _fsrsScheduler = fsrsScheduler ?? FsrsSchedulerAdapter();

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final EdgeFunctionClient _edgeClient;
  final SupabaseClientProvider _supabaseProvider;
  final FsrsSchedulerAdapter _fsrsScheduler;

  /// Fetches due cards for [userId] (optionally scoped to [deckId]).
  Future<List<DueCard>> getDueCards({
    required String userId,
    String? deckId,
    int limit = 50,
  }) async {
    final List<Map<String, dynamic>> localCards = await _database.queryTable(
      'cards',
      userId: userId,
      deckId: deckId,
    );
    final List<Map<String, dynamic>> localStates = await _database.queryTable(
      'card_learning_state',
      userId: userId,
    );

    if (localCards.isNotEmpty) {
      final Map<String, Map<String, dynamic>> stateByCardId =
          <String, Map<String, dynamic>>{
        for (final Map<String, dynamic> s in localStates)
          (s['card_id']?.toString() ?? ''): s,
      };
      final DateTime now = DateTime.now().toUtc();
      final List<DueCard> due = <DueCard>[];

      for (final Map<String, dynamic> card in localCards) {
        if (card['is_suspended'] == true || card['is_buried'] == true) {
          continue;
        }
        final String cardId = card['id']?.toString() ?? '';
        final Map<String, dynamic>? state = stateByCardId[cardId];
        final String dueIso =
            state?['due_date']?.toString() ?? now.toIso8601String();
        final DateTime dueDate = DateTime.tryParse(dueIso)?.toUtc() ?? now;

        if (!dueDate.isAfter(now)) {
          due.add(
            DueCard(
              cardId: cardId,
              deckId: card['deck_id']?.toString() ?? '',
              front: card['front']?.toString() ?? '',
              back: card['back']?.toString() ?? '',
              extra: card['extra']?.toString(),
              cardType: card['card_type']?.toString() ?? 'basic',
              state: state?['state']?.toString() ?? 'new',
              stability: (state?['stability'] as num?)?.toDouble() ?? 0.0,
              difficulty: (state?['difficulty'] as num?)?.toDouble() ?? 0.0,
              dueDate: dueIso,
              reps: (state?['reps'] as num?)?.toInt() ?? 0,
              lapses: (state?['lapses'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }

      if (due.isNotEmpty) {
        return due.take(limit).toList(growable: false);
      }
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> rpcRows = await client.rpc(
          'get_due_cards',
          params: <String, dynamic>{
            'p_user_id': userId,
            'p_deck_id': deckId,
            'p_limit': limit,
          },
        ) as List<dynamic>;
        return rpcRows
            .whereType<Map<String, dynamic>>()
            .map(DueCard.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    if (userId == 'demo-user-id') {
      return demoCards;
    }
    return const <DueCard>[];
  }

  /// Previews the human-readable next intervals (`<10m`, `2d`, `5d`, `12d`) for the 4 FSRS ratings
  /// using the exact same FSRS scheduler adapter used during submission.
  Map<ReviewRating, String> previewIntervals(
    DueCard card, {
    double examBoostMultiplier = 1.0,
  }) {
    return _fsrsScheduler.previewIntervals(
      card,
      examBoostMultiplier: examBoostMultiplier,
    );
  }

  /// Submits a review for [card] using local FSRS scheduling + remote Edge Function / Outbox sync.
  Future<ReviewResponse> submitReview({
    required String userId,
    required DueCard card,
    required ReviewRating rating,
    required int durationMs,
    String? sessionId,
    double examBoostMultiplier = 1.0,
  }) async {
    final String idempotencyKey = CryptoUtils.generateUuidV4();
    final DateTime now = DateTime.now().toUtc();

    final ScheduledReviewSimulation sim = _fsrsScheduler.simulateReview(
      card: card,
      rating: rating,
      now: now,
      examBoostMultiplier: examBoostMultiplier,
    );

    // 1. Update local learning state immediately (< 16ms)
    await _database.upsertRow('card_learning_state', <String, dynamic>{
      'user_id': userId,
      'card_id': card.cardId,
      'state': sim.nextState,
      'due_date': sim.nextDue.toIso8601String(),
      'stability': sim.nextStability,
      'difficulty': sim.nextDifficulty,
      'elapsed_days': 0,
      'scheduled_days': sim.scheduledDays,
      'reps': sim.nextReps,
      'lapses': sim.nextLapses,
      'last_review': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    final Map<String, dynamic> reviewLogPayload = <String, dynamic>{
      'id': CryptoUtils.generateUuidV4(),
      'user_id': userId,
      'card_id': card.cardId,
      'rating': rating.value,
      'state': card.state,
      'scheduled_days': sim.scheduledDays,
      'review_duration_ms': durationMs,
      'idempotency_key': idempotencyKey,
      'session_id': sessionId,
      'reviewed_at': now.toIso8601String(),
    };

    if (_supabaseProvider.isAvailable) {
      try {
        final Map<String, dynamic> remoteResult = await _edgeClient.invoke(
          'review-card',
          body: <String, dynamic>{
            'cardId': card.cardId,
            'rating': rating.value,
            'durationMs': durationMs,
            'idempotencyKey': idempotencyKey,
          },
        );
        return ReviewResponse.fromJson(remoteResult);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'review_logs',
          action: 'insert',
          payload: reviewLogPayload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'review_logs',
        action: 'insert',
        payload: reviewLogPayload,
      );
    }

    return ReviewResponse(
      state: sim.nextState,
      dueDate: sim.nextDue.toIso8601String(),
      intervalDays: sim.scheduledDays.toDouble(),
      stability: sim.nextStability,
      difficulty: sim.nextDifficulty,
      reps: sim.nextReps,
      lapses: sim.nextLapses,
    );
  }
}

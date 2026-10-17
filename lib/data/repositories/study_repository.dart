import 'dart:math' as math;

import 'package:fsrs/fsrs.dart' as fsrs_pkg;

import '../../core/utils/crypto_utils.dart';
import '../../domain/models/due_card.dart';
import '../../domain/models/review_result.dart';
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
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _edgeClient = edgeClient ?? EdgeFunctionClient.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final EdgeFunctionClient _edgeClient;
  final SupabaseClientProvider _supabaseProvider;

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

  /// Previews the human-readable next intervals (`<10m`, `2d`, `5d`, `12d`) for the 4 FSRS ratings.
  Map<ReviewRating, String> previewIntervals(
    DueCard card, {
    double examBoostMultiplier = 1.0,
  }) {
    final Map<ReviewRating, int> daysByRating = <ReviewRating, int>{
      ReviewRating.again: 0,
      ReviewRating.hard: math.max(1, ((card.stability <= 0 ? 1 : card.stability * 1.2) / examBoostMultiplier).round()),
      ReviewRating.good: math.max(1, ((card.stability <= 0 ? 3 : card.stability * 2.5) / examBoostMultiplier).round()),
      ReviewRating.easy: math.max(2, ((card.stability <= 0 ? 7 : card.stability * 3.8) / examBoostMultiplier).round()),
    };

    return <ReviewRating, String>{
      ReviewRating.again: '<10m',
      ReviewRating.hard: '${daysByRating[ReviewRating.hard]}d',
      ReviewRating.good: '${daysByRating[ReviewRating.good]}d',
      ReviewRating.easy: '${daysByRating[ReviewRating.easy]}d',
    };
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

    // Compute local FSRS-6 schedule via Dart fsrs package
    final fsrs_pkg.Scheduler scheduler = fsrs_pkg.Scheduler();
    final fsrs_pkg.Card fsrsCard = fsrs_pkg.Card(cardId: card.cardId.hashCode);
    final fsrs_pkg.Rating mappedRating = switch (rating) {
      ReviewRating.again => fsrs_pkg.Rating.again,
      ReviewRating.hard => fsrs_pkg.Rating.hard,
      ReviewRating.good => fsrs_pkg.Rating.good,
      ReviewRating.easy => fsrs_pkg.Rating.easy,
    };

    final ({fsrs_pkg.Card card, fsrs_pkg.ReviewLog reviewLog}) scheduled =
        scheduler.reviewCard(fsrsCard, mappedRating, reviewDateTime: now);

    int scheduledDays = scheduled.card.due.difference(now).inDays;
    if (examBoostMultiplier > 1.0 && scheduledDays > 1) {
      scheduledDays = math.max(1, (scheduledDays / examBoostMultiplier).round());
    }
    final DateTime nextDue = rating == ReviewRating.again
        ? now.add(const Duration(minutes: 10))
        : now.add(Duration(days: math.max(1, scheduledDays)));

    final String nextState = switch (rating) {
      ReviewRating.again => card.reps == 0 ? 'learning' : 'relearning',
      ReviewRating.hard => 'review',
      ReviewRating.good => 'review',
      ReviewRating.easy => 'review',
    };
    final double nextStability = scheduled.card.stability ??
        (card.stability <= 0 ? rating.value * 1.5 : card.stability * 2.1);
    final double nextDifficulty = scheduled.card.difficulty ??
        (card.difficulty <= 0 ? 5.0 : card.difficulty);
    final int nextReps = card.reps + 1;
    final int nextLapses =
        rating == ReviewRating.again ? card.lapses + 1 : card.lapses;

    // 1. Update local learning state immediately (< 16ms)
    await _database.upsertRow('card_learning_state', <String, dynamic>{
      'user_id': userId,
      'card_id': card.cardId,
      'state': nextState,
      'due_date': nextDue.toIso8601String(),
      'stability': nextStability,
      'difficulty': nextDifficulty,
      'elapsed_days': 0,
      'scheduled_days': math.max(0, scheduledDays),
      'reps': nextReps,
      'lapses': nextLapses,
      'last_review': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    final Map<String, dynamic> reviewLogPayload = <String, dynamic>{
      'id': CryptoUtils.generateUuidV4(),
      'user_id': userId,
      'card_id': card.cardId,
      'rating': rating.value,
      'state': card.state,
      'scheduled_days': math.max(0, scheduledDays),
      'review_duration_ms': durationMs,
      'reviewed_at': now.toIso8601String(),
      'idempotency_key': idempotencyKey,
      if (sessionId != null) 'session_id': sessionId,
    };
    await _database.upsertRow('review_logs', reviewLogPayload);

    // 2. Sync via Edge Function or enqueue to Outbox
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
      state: nextState,
      dueDate: nextDue.toIso8601String(),
      intervalDays: math.max(0, scheduledDays),
      stability: nextStability,
      difficulty: nextDifficulty,
      reps: nextReps,
      lapses: nextLapses,
    );
  }
}

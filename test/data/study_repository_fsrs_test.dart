import 'package:flashi_mobile/data/local/app_database.dart';
import 'package:flashi_mobile/data/local/outbox_queue.dart';
import 'package:flashi_mobile/data/repositories/study_repository.dart';
import 'package:flashi_mobile/domain/models/due_card.dart';
import 'package:flashi_mobile/domain/models/review_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudyRepository FSRS-6 & Offline Outbox', () {
    test('submits review offline, updates local state, and enqueues review_logs to outbox', () async {
      final FlashiLocalDatabase db = FlashiLocalDatabase.inMemory();
      final OutboxQueue outbox = OutboxQueue(database: db);
      final StudyRepository studyRepo = StudyRepository(
        database: db,
        outboxQueue: outbox,
      );

      const DueCard card = DueCard(
        id: 'card-1',
        deckId: 'deck-1',
        noteId: 'note-1',
        front: 'O que e FSRS?',
        back: 'Free Spaced Repetition Scheduler',
        state: 'new',
        reps: 0,
        lapses: 0,
      );

      final ReviewResponse response = await studyRepo.submitReview(
        userId: 'user-test-1',
        card: card,
        rating: ReviewRating.good,
        durationMs: 3200,
        sessionId: 'session-xyz',
      );

      // Verify response
      expect(response.stability, greaterThan(0));
      expect(response.difficulty, greaterThan(0));
      expect(response.reps, 1);

      // Verify local database state was updated
      final Map<String, dynamic>? updatedState =
          await db.getRow('card_learning_state', 'card-1');
      expect(updatedState, isNotNull);
      expect(updatedState?['reps'], 1);
      expect(updatedState?['stability'], equals(response.stability));

      // Verify mutation enqueued in outbox
      expect(outbox.pendingCount, 1);
      final List<Map<String, dynamic>> mutations =
          await db.queryTable('sync_outbox');
      expect(mutations, hasLength(1));
      expect(mutations.first['table_name'], 'review_logs');
      expect(mutations.first['action'], 'insert');
    });

    test('getDueCards returns non-suspended due cards correctly', () async {
      final FlashiLocalDatabase db = FlashiLocalDatabase.inMemory();
      final OutboxQueue outbox = OutboxQueue(database: db);
      final StudyRepository studyRepo = StudyRepository(
        database: db,
        outboxQueue: outbox,
      );

      // Seed card
      await db.upsertRow('cards', <String, dynamic>{
        'id': 'card-due-1',
        'deck_id': 'deck-1',
        'front': 'Pergunta Due',
        'back': 'Resposta Due',
        'user_id': 'user-1',
        'is_suspended': false,
        'is_buried': false,
      });

      // Seed state due today
      await db.upsertRow('card_learning_state', <String, dynamic>{
        'card_id': 'card-due-1',
        'user_id': 'user-1',
        'state': 'review',
        'due_date': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'stability': 5.0,
        'difficulty': 4.0,
        'reps': 3,
        'lapses': 0,
      });

      final List<DueCard> dueCards = await studyRepo.getDueCards(
        userId: 'user-1',
        deckId: 'deck-1',
      );

      expect(dueCards, hasLength(1));
      expect(dueCards.first.cardId, 'card-due-1');
      expect(dueCards.first.front, 'Pergunta Due');
    });
  });
}

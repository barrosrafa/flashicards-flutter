import 'package:flashi_mobile/domain/models/due_card.dart';
import 'package:flashi_mobile/domain/models/review_result.dart';
import 'package:flashi_mobile/domain/services/fsrs_scheduler_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FsrsSchedulerAdapter', () {
    test('simulateReview computes valid intervals for all ratings', () {
      final FsrsSchedulerAdapter adapter = FsrsSchedulerAdapter();
      const DueCard card = DueCard(
        id: 'c1',
        deckId: 'd1',
        noteId: 'n1',
        front: 'Front text',
        back: 'Back text',
        stability: 2.0,
        difficulty: 5.0,
        reps: 1,
        lapses: 0,
      );

      final ScheduledReviewSimulation againRes = adapter.simulateReview(
        card: card,
        rating: ReviewRating.again,
      );
      final ScheduledReviewSimulation goodRes = adapter.simulateReview(
        card: card,
        rating: ReviewRating.good,
      );
      final ScheduledReviewSimulation easyRes = adapter.simulateReview(
        card: card,
        rating: ReviewRating.easy,
      );

      expect(againRes.scheduledDays, lessThanOrEqualTo(1));
      expect(goodRes.scheduledDays, greaterThanOrEqualTo(againRes.scheduledDays));
      expect(easyRes.scheduledDays, greaterThanOrEqualTo(goodRes.scheduledDays));
      expect(againRes.intervalLabel, '<10m');
      expect(goodRes.nextStability, greaterThan(againRes.nextStability));
    });

    test('previewIntervals returns formatted strings for all four ratings', () {
      final FsrsSchedulerAdapter adapter = FsrsSchedulerAdapter();
      const DueCard card = DueCard(
        id: 'c1',
        deckId: 'd1',
        noteId: 'n1',
        front: 'Front',
        back: 'Back',
      );

      final Map<ReviewRating, String> preview = adapter.previewIntervals(card);

      expect(preview.containsKey(ReviewRating.again), isTrue);
      expect(preview.containsKey(ReviewRating.hard), isTrue);
      expect(preview.containsKey(ReviewRating.good), isTrue);
      expect(preview.containsKey(ReviewRating.easy), isTrue);
    });
  });
}

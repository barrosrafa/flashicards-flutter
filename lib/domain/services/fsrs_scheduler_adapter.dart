import 'dart:math' as math;

import 'package:fsrs/fsrs.dart' as fsrs_pkg;

import '../models/due_card.dart';
import '../models/review_result.dart';

class ScheduledReviewSimulation {
  const ScheduledReviewSimulation({
    required this.rating,
    required this.nextDue,
    required this.intervalLabel,
    required this.scheduledDays,
    required this.nextStability,
    required this.nextDifficulty,
    required this.nextState,
    required this.nextReps,
    required this.nextLapses,
  });

  final ReviewRating rating;
  final DateTime nextDue;
  final String intervalLabel;
  final int scheduledDays;
  final double nextStability;
  final double nextDifficulty;
  final String nextState;
  final int nextReps;
  final int nextLapses;
}

/// Adaptador FSRS-6 unificado que encapsula o agendador FSRS e garante que tanto
/// a prévia de intervalos na UI quanto a submissão de revisão compartilhem a mesma
/// função matemática e hidratação de estado.
class FsrsSchedulerAdapter {
  FsrsSchedulerAdapter({
    fsrs_pkg.Scheduler? scheduler,
  }) : _scheduler = scheduler ?? fsrs_pkg.Scheduler();

  final fsrs_pkg.Scheduler _scheduler;

  static double _fallbackStability(double current, ReviewRating rating) {
    if (current <= 0) {
      return switch (rating) {
        ReviewRating.again => 0.4,
        ReviewRating.hard => 1.2,
        ReviewRating.good => 3.1,
        ReviewRating.easy => 7.8,
      };
    }
    return switch (rating) {
      ReviewRating.again => math.max(0.2, current * 0.3),
      ReviewRating.hard => current * 1.2,
      ReviewRating.good => current * 2.3,
      ReviewRating.easy => current * 3.6,
    };
  }

  static double _fallbackDifficulty(double current, ReviewRating rating) {
    final double base = current <= 0 ? 5.0 : current;
    return switch (rating) {
      ReviewRating.again => math.min(10.0, base + 1.2),
      ReviewRating.hard => math.min(10.0, base + 0.5),
      ReviewRating.good => math.max(1.0, base - 0.2),
      ReviewRating.easy => math.max(1.0, base - 1.0),
    };
  }

  static String _formatIntervalLabel(
    ReviewRating rating,
    int scheduledDays,
    DateTime nextDue,
    DateTime now,
  ) {
    if (rating == ReviewRating.again) {
      final Duration diff = nextDue.difference(now);
      if (diff.inMinutes <= 15) return '<10m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '<10m';
    }
    if (scheduledDays <= 0) return '1d';
    if (scheduledDays < 30) return '${scheduledDays}d';
    if (scheduledDays < 365) return '${(scheduledDays / 30).round()}m';
    return '${(scheduledDays / 365).toStringAsFixed(1)}a';
  }

  ScheduledReviewSimulation simulateReview({
    required DueCard card,
    required ReviewRating rating,
    DateTime? now,
    double examBoostMultiplier = 1.0,
  }) {
    final DateTime reviewTime = now ?? DateTime.now().toUtc();
    final fsrs_pkg.Rating fsrsRating = switch (rating) {
      ReviewRating.again => fsrs_pkg.Rating.again,
      ReviewRating.hard => fsrs_pkg.Rating.hard,
      ReviewRating.good => fsrs_pkg.Rating.good,
      ReviewRating.easy => fsrs_pkg.Rating.easy,
    };

    final fsrs_pkg.State currentState = switch (card.state.toLowerCase()) {
      'new' => fsrs_pkg.State.learning,
      'learning' => fsrs_pkg.State.learning,
      'review' => fsrs_pkg.State.review,
      'relearning' => fsrs_pkg.State.relearning,
      _ => card.reps == 0 ? fsrs_pkg.State.learning : fsrs_pkg.State.review,
    };

    final fsrs_pkg.Card hydratedCard = fsrs_pkg.Card(
      cardId: card.cardId.hashCode,
      state: currentState,
      due: card.dueDate != null ? DateTime.tryParse(card.dueDate!) : null,
      stability: card.stability > 0 ? card.stability : null,
      difficulty: card.difficulty > 0 ? card.difficulty : null,
      reps: card.reps,
      lapses: card.lapses,
      lastReview:
          card.lastReview != null ? DateTime.tryParse(card.lastReview!) : null,
    );

    int scheduledDays;
    double stability;
    double difficulty;
    DateTime nextDue;
    String nextState;

    try {
      final scheduled = _scheduler.reviewCard(
        hydratedCard,
        fsrsRating,
        reviewDateTime: reviewTime,
      );
      final int rawDiffDays = scheduled.card.due.difference(reviewTime).inDays;
      scheduledDays = math.max(0, rawDiffDays);
      stability = scheduled.card.stability ?? _fallbackStability(card.stability, rating);
      difficulty = scheduled.card.difficulty ?? _fallbackDifficulty(card.difficulty, rating);
      nextDue = scheduled.card.due;
      nextState = scheduled.card.state.name;
    } catch (_) {
      stability = _fallbackStability(card.stability, rating);
      difficulty = _fallbackDifficulty(card.difficulty, rating);
      scheduledDays = switch (rating) {
        ReviewRating.again => 0,
        ReviewRating.hard => math.max(1, (stability * 1.2).round()),
        ReviewRating.good => math.max(1, (stability * 2.5).round()),
        ReviewRating.easy => math.max(2, (stability * 3.8).round()),
      };
      nextDue = rating == ReviewRating.again
          ? reviewTime.add(const Duration(minutes: 10))
          : reviewTime.add(Duration(days: scheduledDays));
      nextState = rating == ReviewRating.again
          ? (card.reps == 0 ? 'learning' : 'relearning')
          : 'review';
    }

    if (examBoostMultiplier > 1.0 && scheduledDays > 1) {
      scheduledDays = math.max(1, (scheduledDays / examBoostMultiplier).round());
      if (rating != ReviewRating.again) {
        nextDue = reviewTime.add(Duration(days: scheduledDays));
      }
    }

    final String intervalLabel = _formatIntervalLabel(
      rating,
      scheduledDays,
      nextDue,
      reviewTime,
    );

    return ScheduledReviewSimulation(
      rating: rating,
      nextDue: nextDue,
      intervalLabel: intervalLabel,
      scheduledDays: scheduledDays,
      nextStability: stability,
      nextDifficulty: difficulty,
      nextState: nextState,
      nextReps: card.reps + 1,
      nextLapses: rating == ReviewRating.again ? card.lapses + 1 : card.lapses,
    );
  }

  Map<ReviewRating, String> previewIntervals(
    DueCard card, {
    double examBoostMultiplier = 1.0,
    DateTime? now,
  }) {
    final DateTime reviewTime = now ?? DateTime.now().toUtc();
    return <ReviewRating, String>{
      for (final ReviewRating rating in ReviewRating.values)
        rating: simulateReview(
          card: card,
          rating: rating,
          now: reviewTime,
          examBoostMultiplier: examBoostMultiplier,
        ).intervalLabel,
    };
  }
}

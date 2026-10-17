/// Study analytics, retention telemetry, and FSRS-6 optimization status models.
///
/// Mirrors `src/lib/services/analytics-service.ts` and `optimizer-service.ts` from `app-flashi`.
class AnalyticsDay {
  const AnalyticsDay({
    required this.date,
    required this.cardsReviewed,
    required this.newCardsLearned,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.totalTimeMs,
  });

  final String date;
  final int cardsReviewed;
  final int newCardsLearned;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int totalTimeMs;

  double get accuracyRate {
    if (cardsReviewed <= 0) {
      return 0;
    }
    return ((hardCount + goodCount + easyCount) / cardsReviewed) * 100.0;
  }

  factory AnalyticsDay.fromJson(Map<String, dynamic> json) {
    return AnalyticsDay(
      date: json['date']?.toString() ?? '',
      cardsReviewed: (json['cards_reviewed'] as num?)?.toInt() ?? 0,
      newCardsLearned: (json['new_cards_learned'] as num?)?.toInt() ?? 0,
      againCount: (json['again_count'] as num?)?.toInt() ?? 0,
      hardCount: (json['hard_count'] as num?)?.toInt() ?? 0,
      goodCount: (json['good_count'] as num?)?.toInt() ?? 0,
      easyCount: (json['easy_count'] as num?)?.toInt() ?? 0,
      totalTimeMs: (json['total_time_ms'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date,
      'cards_reviewed': cardsReviewed,
      'new_cards_learned': newCardsLearned,
      'again_count': againCount,
      'hard_count': hardCount,
      'good_count': goodCount,
      'easy_count': easyCount,
      'total_time_ms': totalTimeMs,
    };
  }
}

/// Aggregated analytics dataset across a date range.
class AnalyticsData {
  const AnalyticsData({
    required this.days,
    required this.totalReviews,
    required this.totalNewLearned,
    required this.totalTimeMs,
    required this.accuracyRate,
    required this.currentStreak,
    required this.longestStreak,
  });

  final List<AnalyticsDay> days;
  final int totalReviews;
  final int totalNewLearned;
  final int totalTimeMs;
  final int accuracyRate;
  final int currentStreak;
  final int longestStreak;
}

/// Deck-level retention curve data point from `get_deck_true_retention`.
class DeckRetentionPoint {
  const DeckRetentionPoint({
    required this.reviewDate,
    required this.totalMatureReviews,
    required this.passedReviews,
    required this.trueRetentionRate,
  });

  final String reviewDate;
  final int totalMatureReviews;
  final int passedReviews;
  final double trueRetentionRate;

  factory DeckRetentionPoint.fromJson(Map<String, dynamic> json) {
    return DeckRetentionPoint(
      reviewDate: json['review_date']?.toString() ?? '',
      totalMatureReviews: (json['total_mature_reviews'] as num?)?.toInt() ?? 0,
      passedReviews: (json['passed_reviews'] as num?)?.toInt() ?? 0,
      trueRetentionRate:
          (json['true_retention_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// FSRS-6 optimization status and 21-weight vector.
class FsrsOptimizationStatus {
  const FsrsOptimizationStatus({
    required this.canOptimize,
    required this.reviewCount,
    required this.minRequired,
    this.currentWeights,
    this.lastOptimizedAt,
  });

  final bool canOptimize;
  final int reviewCount;
  final int minRequired;
  final List<double>? currentWeights;
  final String? lastOptimizedAt;

  /// Default FSRS-6 21-parameter weight vector used by `app-flashi`.
  static const List<double> defaultFsrs6Weights = <double>[
    0.212,
    1.2931,
    2.3065,
    8.2956,
    6.4133,
    0.8334,
    3.0194,
    0.001,
    1.8722,
    0.1666,
    0.796,
    1.4835,
    0.0614,
    0.2629,
    1.6483,
    0.6014,
    1.8729,
    0.5425,
    0.0912,
    0.0658,
    0.1542,
  ];
}

/// Avaliações FSRS-6 e resposta de submissão de revisão.
enum ReviewRating {
  again('again', 'De novo', 1),
  hard('hard', 'Difícil', 2),
  good('good', 'Bom', 3),
  easy('easy', 'Fácil', 4);

  const ReviewRating(this.key, this.labelPtBr, this.shortcutNumber);
  final String key;
  final String labelPtBr;
  final int shortcutNumber;

  static ReviewRating fromString(String raw) {
    return ReviewRating.values.firstWhere(
      (r) => r.key == raw,
      orElse: () => ReviewRating.good,
    );
  }
}

class ReviewResponse {
  const ReviewResponse({
    required this.queued,
    required this.confirmed,
    required this.clientReviewId,
    this.intervalDays,
    this.dueAt,
  });

  final bool queued;
  final bool confirmed;
  final String clientReviewId;
  final double? intervalDays;
  final String? dueAt;
}

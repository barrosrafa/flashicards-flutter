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

  /// Retorna o valor numérico (1=again, 2=hard, 3=good, 4=easy) compatível com FSRS.
  int get value => shortcutNumber;

  static ReviewRating fromString(String raw) {
    return ReviewRating.values.firstWhere(
      (ReviewRating r) => r.key == raw || r.name == raw || r.value.toString() == raw,
      orElse: () => ReviewRating.good,
    );
  }

  static ReviewRating fromInt(int val) {
    return ReviewRating.values.firstWhere(
      (ReviewRating r) => r.value == val,
      orElse: () => ReviewRating.good,
    );
  }
}

class ReviewResponse {
  const ReviewResponse({
    this.queued = false,
    this.confirmed = true,
    this.clientReviewId,
    this.intervalDays,
    this.dueAt,
    this.dueDate,
    this.state,
    this.stability,
    this.difficulty,
    this.reps,
    this.lapses,
  });

  final bool queued;
  final bool confirmed;
  final String? clientReviewId;
  final double? intervalDays;
  final String? dueAt;
  final String? dueDate;
  final String? state;
  final double? stability;
  final double? difficulty;
  final int? reps;
  final int? lapses;

  String? get nextDue => dueDate ?? dueAt;

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      queued: json['queued'] == true || json['queued'] == 1,
      confirmed: json['confirmed'] != false && json['confirmed'] != 0,
      clientReviewId: (json['clientReviewId'] ?? json['client_review_id'] ?? json['review_id'])?.toString(),
      intervalDays: (json['intervalDays'] ?? json['interval_days'] ?? json['scheduled_days'] as num?)?.toDouble(),
      dueAt: (json['dueAt'] ?? json['due_at'] ?? json['next_due'])?.toString(),
      dueDate: (json['dueDate'] ?? json['due_date'] ?? json['next_due'])?.toString(),
      state: json['state']?.toString(),
      stability: (json['stability'] as num?)?.toDouble(),
      difficulty: (json['difficulty'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      lapses: (json['lapses'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'queued': queued,
        'confirmed': confirmed,
        if (clientReviewId != null) 'client_review_id': clientReviewId,
        if (intervalDays != null) 'interval_days': intervalDays,
        if (dueAt != null) 'due_at': dueAt,
        if (dueDate != null) 'due_date': dueDate,
        if (state != null) 'state': state,
        if (stability != null) 'stability': stability,
        if (difficulty != null) 'difficulty': difficulty,
        if (reps != null) 'reps': reps,
        if (lapses != null) 'lapses': lapses,
      };
}

/// Registro imutável de histórico de revisão para sincronização e cálculo de retenção.
class CardReviewLog {
  const CardReviewLog({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.state,
    this.due,
    this.stability = 0.0,
    this.difficulty = 0.0,
    this.elapsedDays = 0,
    this.lastElapsedDays = 0,
    this.scheduledDays = 0,
    this.reviewTime,
    this.durationMs = 0,
  });

  final String id;
  final String cardId;
  final ReviewRating rating;
  final String state;
  final String? due;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int lastElapsedDays;
  final int scheduledDays;
  final String? reviewTime;
  final int durationMs;

  factory CardReviewLog.fromJson(Map<String, dynamic> json) {
    return CardReviewLog(
      id: (json['id'] ?? '').toString(),
      cardId: (json['card_id'] ?? json['cardId'] ?? '').toString(),
      rating: ReviewRating.fromString((json['rating'] ?? 'good').toString()),
      state: (json['state'] ?? 'review').toString(),
      due: json['due']?.toString(),
      stability: (json['stability'] as num?)?.toDouble() ?? 0.0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.0,
      elapsedDays: (json['elapsed_days'] as num?)?.toInt() ?? 0,
      lastElapsedDays: (json['last_elapsed_days'] as num?)?.toInt() ?? 0,
      scheduledDays: (json['scheduled_days'] as num?)?.toInt() ?? 0,
      reviewTime: (json['review_time'] ?? json['created_at'])?.toString(),
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'card_id': cardId,
        'rating': rating.value,
        'state': state,
        if (due != null) 'due': due,
        'stability': stability,
        'difficulty': difficulty,
        'elapsed_days': elapsedDays,
        'last_elapsed_days': lastElapsedDays,
        'scheduled_days': scheduledDays,
        if (reviewTime != null) 'review_time': reviewTime,
        'duration_ms': durationMs,
      };
}

import 'dart:convert';

/// Item da fila de estudo FSRS-6 equivalente a `DueCard` em `lib/services/study-service.ts`.
class DueCard {
  const DueCard({
    required this.cardId,
    required this.deckId,
    Map<String, dynamic>? fields,
    String? front,
    String? back,
    this.extra,
    String? cardType,
    String? cardKind,
    this.state = 'new',
    String? dueAt,
    String? dueDate,
    num? intervalDays,
    this.stability = 0.0,
    this.difficulty = 0.0,
    this.reps = 0,
    this.lapses = 0,
    this.lastReview,
    this.examId,
    this.examName,
    this.targetDate,
    this.daysRemaining,
    this.schedulingFactor,
    this.cardOrdinal = 0,
    this.templateId,
    this.noteId,
  })  : fields = fields ??
            <String, dynamic>{
              if (front != null) 'front': front,
              if (back != null) 'back': back,
              if (extra != null) 'extra': extra,
            },
        cardKind = cardKind ?? cardType ?? 'basic',
        dueAt = dueAt ?? dueDate ?? '',
        intervalDays = (intervalDays ?? 0).toDouble();

  final String cardId;
  final String deckId;
  final Map<String, dynamic> fields;
  final String state; // 'new' | 'learning' | 'review' | 'relearning'
  final String dueAt;
  String get dueDate => dueAt;
  final double intervalDays;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final String? lastReview;
  final String? examId;
  final String? examName;
  final String? targetDate;
  final int? daysRemaining;
  final double? schedulingFactor;
  final int cardOrdinal;
  final String? templateId;
  final String cardKind;
  String get cardType => cardKind;
  final String? noteId;
  final String? extra;

  String get front =>
      (fields['__flashi_rendered_front'] ??
              fields['front'] ??
              fields['Front'] ??
              fields['text'] ??
              fields['Text'] ??
              '')
          .toString();

  String get back =>
      (fields['__flashi_rendered_back'] ??
              fields['back'] ??
              fields['Back'] ??
              fields['extra'] ??
              fields['Extra'] ??
              '')
          .toString();

  DueCard copyWith({
    Map<String, dynamic>? fields,
    String? front,
    String? back,
    String? extra,
    String? state,
    String? dueAt,
    String? dueDate,
    double? intervalDays,
    double? stability,
    double? difficulty,
    int? reps,
    int? lapses,
    String? lastReview,
    int? cardOrdinal,
    String? templateId,
    String? cardKind,
    String? cardType,
    String? noteId,
  }) {
    return DueCard(
      cardId: cardId,
      deckId: deckId,
      fields: fields ?? this.fields,
      front: front ?? this.front,
      back: back ?? this.back,
      extra: extra ?? this.extra,
      state: state ?? this.state,
      dueAt: dueAt ?? dueDate ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReview: lastReview ?? this.lastReview,
      examId: examId,
      examName: examName,
      targetDate: targetDate,
      daysRemaining: daysRemaining,
      schedulingFactor: schedulingFactor,
      cardOrdinal: cardOrdinal ?? this.cardOrdinal,
      templateId: templateId ?? this.templateId,
      cardKind: cardKind ?? cardType ?? this.cardKind,
      noteId: noteId ?? this.noteId,
    );
  }

  factory DueCard.fromJson(Map<String, dynamic> json) {
    final dynamic rawFields = json['fields'] ?? json['field_values'];
    Map<String, dynamic> parsedFields = const <String, dynamic>{};
    if (rawFields is Map<String, dynamic>) {
      parsedFields = Map<String, dynamic>.from(rawFields);
    } else if (rawFields is Map) {
      parsedFields = rawFields.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v),
      );
    } else if (rawFields is String && rawFields.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rawFields);
        if (decoded is Map<String, dynamic>) parsedFields = decoded;
      } catch (_) {}
    }

    if (parsedFields.isEmpty) {
      parsedFields = <String, dynamic>{
        if (json['front'] != null) 'front': json['front'],
        if (json['back'] != null) 'back': json['back'],
        if (json['extra'] != null) 'extra': json['extra'],
      };
    }

    return DueCard(
      cardId: (json['card_id'] ?? json['id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      fields: parsedFields,
      front: json['front']?.toString(),
      back: json['back']?.toString(),
      extra: json['extra']?.toString() ?? parsedFields['extra']?.toString(),
      state: (json['state'] ?? 'new').toString(),
      dueAt: (json['due_at'] ??
              json['due_date'] ??
              DateTime.now().toUtc().toIso8601String())
          .toString(),
      intervalDays:
          (json['interval_days'] ?? json['scheduled_days'] as num?)?.toDouble() ??
              0,
      stability: (json['stability'] as num?)?.toDouble() ?? 0.0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      lapses: (json['lapses'] as num?)?.toInt() ?? 0,
      lastReview: json['last_review']?.toString(),
      examId: json['exam_id']?.toString(),
      examName: json['exam_name']?.toString(),
      targetDate: json['target_date']?.toString(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      schedulingFactor: (json['scheduling_factor'] as num?)?.toDouble(),
      cardOrdinal:
          (json['card_ordinal'] ?? json['card_ord'] as num?)?.toInt() ?? 0,
      templateId: json['template_id']?.toString(),
      cardKind:
          (json['card_kind'] ?? json['card_type'] ?? 'basic').toString(),
      noteId: json['note_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'card_id': cardId,
      'id': cardId,
      'deck_id': deckId,
      'fields': fields,
      'field_values': fields,
      'front': front,
      'back': back,
      if (extra != null) 'extra': extra,
      'state': state,
      'due_at': dueAt,
      'due_date': dueAt,
      'interval_days': intervalDays,
      'scheduled_days': intervalDays.toInt(),
      'stability': stability,
      'difficulty': difficulty,
      'reps': reps,
      'lapses': lapses,
      if (lastReview != null) 'last_review': lastReview,
      'exam_id': examId,
      'exam_name': examName,
      'target_date': targetDate,
      'days_remaining': daysRemaining,
      'scheduling_factor': schedulingFactor,
      'card_ordinal': cardOrdinal,
      'card_ord': cardOrdinal,
      'template_id': templateId,
      'card_kind': cardKind,
      'card_type': cardKind,
      'note_id': noteId,
    };
  }

  static List<DueCard> get demoCards => <DueCard>[
        DueCard(
          cardId: 'demo-card-001',
          deckId: 'demo',
          fields: const <String, dynamic>{
            'front': 'O que é repetição espaçada?',
            'back':
                'Um método que organiza as revisões ao longo do tempo para ajudar você a recuperar o conteúdo da memória exatamente antes do esquecimento.',
          },
          state: 'new',
          dueAt: DateTime.now().toUtc().toIso8601String(),
          intervalDays: 0,
        ),
        DueCard(
          cardId: 'demo-card-002',
          deckId: 'demo',
          fields: const <String, dynamic>{
            'front': 'Por que tentar lembrar antes de revelar a resposta?',
            'back':
                'A recuperação ativa fortalece as conexões sinápticas, tornando o estudo muito mais eficiente do que apenas reler resumos.',
          },
          state: 'new',
          dueAt: DateTime.now().toUtc().toIso8601String(),
          intervalDays: 0,
        ),
        DueCard(
          cardId: 'demo-card-003',
          deckId: 'demo',
          fields: const <String, dynamic>{
            'front': 'O que acontece quando você avalia uma resposta no Flashi?',
            'back':
                'O motor FSRS-6 recalcula a estabilidade e dificuldade da memória e agenda o próximo intervalo ideal — funcionando 100% offline.',
          },
          state: 'new',
          dueAt: DateTime.now().toUtc().toIso8601String(),
          intervalDays: 0,
        ),
      ];
}

/// Getter top-level para compatibilidade
List<DueCard> get demoCards => DueCard.demoCards;

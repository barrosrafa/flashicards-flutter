import 'dart:convert';

/// Item da fila de estudo FSRS-6 equivalente a `DueCard` em `lib/services/study-service.ts`.
class DueCard {
  const DueCard({
    required this.cardId,
    required this.deckId,
    required this.fields,
    required this.state,
    required this.dueAt,
    required this.intervalDays,
    this.examId,
    this.examName,
    this.targetDate,
    this.daysRemaining,
    this.schedulingFactor,
    this.cardOrdinal = 0,
    this.templateId,
    this.cardKind = 'basic',
    this.noteId,
  });

  final String cardId;
  final String deckId;
  final Map<String, dynamic> fields;
  final String state; // 'new' | 'learning' | 'review' | 'relearning'
  final String dueAt;
  final double intervalDays;
  final String? examId;
  final String? examName;
  final String? targetDate;
  final int? daysRemaining;
  final double? schedulingFactor;
  final int cardOrdinal;
  final String? templateId;
  final String cardKind;
  final String? noteId;

  String get front =>
      (fields['__flashi_rendered_front'] ?? fields['front'] ?? fields['Front'] ?? '')
          .toString();

  String get back =>
      (fields['__flashi_rendered_back'] ?? fields['back'] ?? fields['Back'] ?? '')
          .toString();

  DueCard copyWith({
    Map<String, dynamic>? fields,
    int? cardOrdinal,
    String? templateId,
    String? cardKind,
    String? noteId,
  }) {
    return DueCard(
      cardId: cardId,
      deckId: deckId,
      fields: fields ?? this.fields,
      state: state,
      dueAt: dueAt,
      intervalDays: intervalDays,
      examId: examId,
      examName: examName,
      targetDate: targetDate,
      daysRemaining: daysRemaining,
      schedulingFactor: schedulingFactor,
      cardOrdinal: cardOrdinal ?? this.cardOrdinal,
      templateId: templateId ?? this.templateId,
      cardKind: cardKind ?? this.cardKind,
      noteId: noteId ?? this.noteId,
    );
  }

  factory DueCard.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    Map<String, dynamic> parsedFields = const {};
    if (rawFields is Map<String, dynamic>) {
      parsedFields = rawFields;
    } else if (rawFields is String && rawFields.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFields);
        if (decoded is Map<String, dynamic>) parsedFields = decoded;
      } catch (_) {}
    }

    return DueCard(
      cardId: (json['card_id'] ?? json['id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      fields: parsedFields,
      state: (json['state'] ?? 'new').toString(),
      dueAt: (json['due_at'] ?? DateTime.now().toUtc().toIso8601String())
          .toString(),
      intervalDays: (json['interval_days'] as num?)?.toDouble() ?? 0,
      examId: json['exam_id']?.toString(),
      examName: json['exam_name']?.toString(),
      targetDate: json['target_date']?.toString(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      schedulingFactor: (json['scheduling_factor'] as num?)?.toDouble(),
      cardOrdinal: (json['card_ordinal'] as num?)?.toInt() ?? 0,
      templateId: json['template_id']?.toString(),
      cardKind: (json['card_kind'] ?? 'basic').toString(),
      noteId: json['note_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'deck_id': deckId,
      'fields': fields,
      'state': state,
      'due_at': dueAt,
      'interval_days': intervalDays,
      'exam_id': examId,
      'exam_name': examName,
      'target_date': targetDate,
      'days_remaining': daysRemaining,
      'scheduling_factor': schedulingFactor,
      'card_ordinal': cardOrdinal,
      'template_id': templateId,
      'card_kind': cardKind,
      'note_id': noteId,
    };
  }

  static List<DueCard> get demoCards => [
        DueCard(
          cardId: 'demo-card-001',
          deckId: 'demo',
          fields: const {
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
          fields: const {
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
          fields: const {
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

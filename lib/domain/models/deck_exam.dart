/// Modelo de Agendamento de Exame por Prioridade (`deck_exams`).
enum ExamPriority {
  examUrgent('exam_urgent', 'Exame Urgente'),
  currentlyStudying('currently_studying', 'Estudando Agora'),
  maintaining('maintaining', 'Manutenção'),
  paused('paused', 'Pausado');

  const ExamPriority(this.value, this.labelPtBr);
  final String value;
  final String labelPtBr;

  static ExamPriority fromString(String? raw) {
    return ExamPriority.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ExamPriority.currentlyStudying,
    );
  }
}

enum ExamStatus {
  active('active', 'Ativo'),
  paused('paused', 'Pausado'),
  completed('completed', 'Concluído'),
  cancelled('cancelled', 'Cancelado');

  const ExamStatus(this.value, this.labelPtBr);
  final String value;
  final String labelPtBr;

  static ExamStatus fromString(String? raw) {
    return ExamStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ExamStatus.active,
    );
  }
}

class DeckExam {
  const DeckExam({
    required this.id,
    required this.userId,
    required this.deckId,
    required this.examName,
    required this.targetDate,
    this.priorityLevel = ExamPriority.currentlyStudying,
    this.status = ExamStatus.active,
    this.usn = 0,
  });

  final String id;
  final String userId;
  final String deckId;
  final String examName;
  final String targetDate;
  final ExamPriority priorityLevel;
  final ExamStatus status;
  final int usn;

  int get daysRemaining {
    final target = DateTime.tryParse('${targetDate}T23:59:59Z');
    if (target == null) return 0;
    return target.difference(DateTime.now().toUtc()).inDays;
  }

  double get schedulingFactor {
    final days = daysRemaining;
    if (days <= 0) return 2.0;
    if (days <= 7) return 1.5;
    if (days <= 30) return 1.2;
    return 1.0;
  }

  factory DeckExam.fromJson(Map<String, dynamic> json) {
    return DeckExam(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      examName: (json['exam_name'] ?? '').toString(),
      targetDate: (json['target_date'] ?? '').toString(),
      priorityLevel:
          ExamPriority.fromString(json['priority_level']?.toString()),
      status: ExamStatus.fromString(json['status']?.toString()),
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'deck_id': deckId,
        'exam_name': examName,
        'target_date': targetDate,
        'priority_level': priorityLevel.value,
        'status': status.value,
        'usn': usn,
      };
}

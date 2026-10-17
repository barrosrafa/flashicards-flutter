/// Modelo de Agendamento de Exame por Prioridade (`deck_exams`).
enum ExamPriority {
  high('high', 'Alta / Urgente'),
  examUrgent('exam_urgent', 'Exame Urgente'),
  currentlyStudying('currently_studying', 'Estudando Agora'),
  maintaining('maintaining', 'Manutenção'),
  paused('paused', 'Pausado'),
  normal('normal', 'Normal'),
  low('low', 'Baixa');

  const ExamPriority(this.value, this.labelPtBr);
  final String value;
  final String labelPtBr;

  static ExamPriority fromString(String? raw) {
    if (raw == null || raw.isEmpty) return ExamPriority.currentlyStudying;
    return ExamPriority.values.firstWhere(
      (ExamPriority e) => e.value.toLowerCase() == raw.toLowerCase() || e.name.toLowerCase() == raw.toLowerCase(),
      orElse: () {
        if (raw.toLowerCase() == 'high') return ExamPriority.high;
        if (raw.toLowerCase() == 'urgent' || raw.toLowerCase() == 'exam_urgent') return ExamPriority.examUrgent;
        return ExamPriority.currentlyStudying;
      },
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
    if (raw == null || raw.isEmpty) return ExamStatus.active;
    return ExamStatus.values.firstWhere(
      (ExamStatus e) => e.value.toLowerCase() == raw.toLowerCase() || e.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => ExamStatus.active,
    );
  }
}

class DeckExam {
  const DeckExam({
    required this.id,
    required this.userId,
    required this.deckId,
    String? title,
    String? examName,
    String? examDate,
    String? targetDate,
    ExamPriority? priority,
    ExamPriority? priorityLevel,
    this.status = ExamStatus.active,
    this.usn = 0,
  })  : title = title ?? examName ?? 'Exame',
        examDate = examDate ?? targetDate ?? '',
        priorityLevel = priorityLevel ?? priority ?? ExamPriority.currentlyStudying;

  final String id;
  final String userId;
  final String deckId;
  final String title;
  final String examDate;
  final ExamPriority priorityLevel;
  final ExamStatus status;
  final int usn;

  String get examName => title;
  String get targetDate => examDate;
  ExamPriority get priority => priorityLevel;

  int get daysRemaining {
    final DateTime? target = DateTime.tryParse('${examDate.replaceAll('Z', '')}T23:59:59Z');
    if (target == null) return 0;
    final int diff = target.difference(DateTime.now().toUtc()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double computeIntervalBoostMultiplier() {
    final int days = daysRemaining;
    if (days <= 0) return 2.0;
    if (days <= 7) return 1.5;
    if (days <= 30) return 1.2;
    return 1.0;
  }

  double get schedulingFactor => computeIntervalBoostMultiplier();

  factory DeckExam.fromJson(Map<String, dynamic> json) {
    return DeckExam(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      deckId: (json['deck_id'] ?? json['deckId'] ?? '').toString(),
      title: (json['title'] ?? json['exam_name'] ?? json['examName'] ?? '').toString(),
      examDate: (json['exam_date'] ?? json['examDate'] ?? json['target_date'] ?? json['targetDate'] ?? '').toString(),
      priorityLevel: ExamPriority.fromString(
        (json['priority_level'] ?? json['priority'] ?? json['priorityLevel'])?.toString(),
      ),
      status: ExamStatus.fromString((json['status'] ?? 'active').toString()),
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'deck_id': deckId,
        'title': title,
        'exam_name': title,
        'exam_date': examDate,
        'target_date': examDate,
        'priority_level': priorityLevel.value,
        'status': status.value,
        'usn': usn,
      };
}

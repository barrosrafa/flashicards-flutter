/// Socratic AI Tutor remediation session models.
///
/// Mirrors `src/lib/services/socratic-service.ts` from `app-flashi`.
enum SocraticStatus {
  started('started'),
  inProgress('in_progress'),
  resolved('resolved'),
  abandoned('abandoned');

  const SocraticStatus(this.value);
  final String value;

  static SocraticStatus fromString(String? raw) {
    return SocraticStatus.values.firstWhere(
      (SocraticStatus s) => s.value == raw,
      orElse: () => SocraticStatus.started,
    );
  }
}

/// A single turn in a Socratic remediation dialogue.
class SocraticMessage {
  const SocraticMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// `'ai'` or `'user'`
  final String role;
  final String content;
  final String timestamp;

  bool get isAi => role == 'ai' || role == 'assistant';

  factory SocraticMessage.fromJson(Map<String, dynamic> json) {
    return SocraticMessage(
      role: json['role']?.toString() ?? 'ai',
      content: json['content']?.toString() ?? '',
      timestamp:
          json['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role,
      'content': content,
      'timestamp': timestamp,
    };
  }
}

/// Active or completed Socratic remediation session for a lapsed card.
class SocraticSession {
  const SocraticSession({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.status,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String cardId;
  final SocraticStatus status;
  final List<SocraticMessage> messages;
  final String createdAt;
  final String updatedAt;

  factory SocraticSession.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMessages =
        json['messages'] as List<dynamic>? ?? const <dynamic>[];
    return SocraticSession(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      cardId: json['card_id']?.toString() ?? '',
      status: SocraticStatus.fromString(json['status']?.toString()),
      messages: rawMessages
          .whereType<Map<String, dynamic>>()
          .map(SocraticMessage.fromJson)
          .toList(growable: false),
      createdAt:
          json['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      updatedAt:
          json['updated_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'card_id': cardId,
      'status': status.value,
      'messages': messages.map((SocraticMessage m) => m.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

/// Modelos de domínio para Decks, Configurações de Deck e Colaboradores.
enum DeckVisibility {
  private('private'),
  shared('shared'),
  public('public');

  const DeckVisibility(this.value);
  final String value;

  static DeckVisibility fromString(String? raw) {
    return DeckVisibility.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => DeckVisibility.private,
    );
  }
}

class Deck {
  const Deck({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.visibility = DeckVisibility.private,
    this.parentDeckId,
    this.deletedAt,
    this.isArchived = false,
    this.cardCount = 0,
    this.newCount = 0,
    this.reviewCount = 0,
    this.progress = 0,
    this.usn = 0,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final DeckVisibility visibility;
  final String? parentDeckId;
  final String? deletedAt;
  final bool isArchived;
  final int cardCount;
  final int newCount;
  final int reviewCount;
  final int progress;
  final int usn;

  Deck copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DeckVisibility? visibility,
    String? parentDeckId,
    String? deletedAt,
    bool? isArchived,
    int? cardCount,
    int? newCount,
    int? reviewCount,
    int? progress,
    int? usn,
  }) {
    return Deck(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      parentDeckId: parentDeckId ?? this.parentDeckId,
      deletedAt: deletedAt ?? this.deletedAt,
      isArchived: isArchived ?? this.isArchived,
      cardCount: cardCount ?? this.cardCount,
      newCount: newCount ?? this.newCount,
      reviewCount: reviewCount ?? this.reviewCount,
      progress: progress ?? this.progress,
      usn: usn ?? this.usn,
    );
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      visibility: DeckVisibility.fromString(json['visibility']?.toString()),
      parentDeckId: json['parent_deck_id']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      isArchived: json['is_archived'] == true || json['is_archived'] == 1,
      cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
      newCount: (json['newCount'] as num?)?.toInt() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'visibility': visibility.value,
      'parent_deck_id': parentDeckId,
      'deleted_at': deletedAt,
      'is_archived': isArchived,
      'cardCount': cardCount,
      'newCount': newCount,
      'reviewCount': reviewCount,
      'progress': progress,
      'usn': usn,
    };
  }
}

class DeckSettings {
  const DeckSettings({
    required this.userId,
    required this.deckId,
    this.overrides = const {},
    this.isFavorite = false,
    this.displayOrder = 0,
  });

  final String userId;
  final String deckId;
  final Map<String, dynamic> overrides;
  final bool isFavorite;
  final int displayOrder;

  factory DeckSettings.fromJson(Map<String, dynamic> json) {
    final rawOverrides = json['overrides'];
    return DeckSettings(
      userId: (json['user_id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      overrides: rawOverrides is Map<String, dynamic>
          ? rawOverrides
          : const <String, dynamic>{},
      isFavorite: json['is_favorite'] == true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeckCollaborator {
  const DeckCollaborator({
    required this.deckId,
    required this.userId,
    required this.role,
    this.createdAt,
  });

  final String deckId;
  final String userId;
  final String role; // 'viewer' | 'editor'
  final String? createdAt;

  factory DeckCollaborator.fromJson(Map<String, dynamic> json) {
    return DeckCollaborator(
      deckId: (json['deck_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      role: (json['role'] ?? 'viewer').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class CollaborationInvite {
  const CollaborationInvite({
    required this.inviteId,
    required this.inviteToken,
    required this.deckId,
    required this.email,
    required this.role,
    this.expiresAt,
  });

  final String inviteId;
  final String inviteToken;
  final String deckId;
  final String email;
  final String role;
  final String? expiresAt;

  factory CollaborationInvite.fromJson(Map<String, dynamic> json) {
    return CollaborationInvite(
      inviteId: (json['invite_id'] ?? json['id'] ?? '').toString(),
      inviteToken: (json['invite_token'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'viewer').toString(),
      expiresAt: json['expires_at']?.toString(),
    );
  }
}

/// Modelos de domínio para Decks, Configurações de Deck e Colaboradores.
enum DeckVisibility {
  private('private'),
  unlisted('unlisted'),
  shared('shared'),
  public('public');

  const DeckVisibility(this.value);
  final String value;

  static DeckVisibility fromString(String? raw) {
    return DeckVisibility.values.firstWhere(
      (DeckVisibility e) => e.value == raw,
      orElse: () => DeckVisibility.private,
    );
  }
}

class Deck {
  const Deck({
    required this.id,
    required this.userId,
    String? name,
    String? title,
    this.description,
    this.color = '#00F2FE',
    this.icon = 'layers',
    this.visibility = DeckVisibility.private,
    this.parentDeckId,
    this.position = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isArchived = false,
    this.cardCount = 0,
    this.newCount = 0,
    this.reviewCount = 0,
    this.progress = 0,
    this.usn = 0,
  }) : name = (name != null && name.isNotEmpty) ? name : (title ?? '');

  final String id;
  final String userId;
  final String name;
  String get title => name;
  final String? description;
  final String color;
  final String icon;
  final DeckVisibility visibility;
  final String? parentDeckId;
  final int position;
  final String? createdAt;
  final String? updatedAt;
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
    String? title,
    String? description,
    String? color,
    String? icon,
    DeckVisibility? visibility,
    String? parentDeckId,
    int? position,
    String? createdAt,
    String? updatedAt,
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
      name: name ?? title ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      visibility: visibility ?? this.visibility,
      parentDeckId: parentDeckId ?? this.parentDeckId,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    final String resolvedName =
        (json['name'] ?? json['title'] ?? '').toString().trim();
    return Deck(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      name: resolvedName,
      description: json['description']?.toString(),
      color: (json['color'] ?? '#00F2FE').toString(),
      icon: (json['icon'] ?? 'layers').toString(),
      visibility: DeckVisibility.fromString(json['visibility']?.toString()),
      parentDeckId: json['parent_deck_id']?.toString(),
      position: (json['position'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      isArchived: json['is_archived'] == true || json['is_archived'] == 1,
      cardCount: (json['cardCount'] ?? json['card_count'] as num?)?.toInt() ?? 0,
      newCount: (json['newCount'] ?? json['new_count'] as num?)?.toInt() ?? 0,
      reviewCount:
          (json['reviewCount'] ?? json['review_count'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'title': name,
      'description': description,
      'color': color,
      'icon': icon,
      'visibility': visibility.value,
      'parent_deck_id': parentDeckId,
      'position': position,
      'created_at': createdAt,
      'updated_at': updatedAt,
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
    this.overrides = const <String, dynamic>{},
    int? dailyNewCardsLimit,
    int? dailyReviewsLimit,
    double? desiredRetention,
    this.isFavorite = false,
    this.displayOrder = 0,
  })  : _dailyNewCardsLimit = dailyNewCardsLimit,
        _dailyReviewsLimit = dailyReviewsLimit,
        _desiredRetention = desiredRetention;

  final String userId;
  final String deckId;
  final Map<String, dynamic> overrides;
  final int? _dailyNewCardsLimit;
  final int? _dailyReviewsLimit;
  final double? _desiredRetention;
  final bool isFavorite;
  final int displayOrder;

  int get dailyNewCardsLimit =>
      _dailyNewCardsLimit ??
      (overrides['daily_new_cards_limit'] as num?)?.toInt() ??
      20;

  int get dailyReviewsLimit =>
      _dailyReviewsLimit ??
      (overrides['daily_reviews_limit'] as num?)?.toInt() ??
      200;

  double get desiredRetention =>
      (_desiredRetention ??
              (overrides['desired_retention'] as num?)?.toDouble() ??
              0.90)
          .clamp(0.70, 0.99);

  factory DeckSettings.fromJson(Map<String, dynamic> json) {
    final dynamic rawOverrides = json['overrides'];
    final Map<String, dynamic> parsedOverrides =
        rawOverrides is Map<String, dynamic>
            ? Map<String, dynamic>.from(rawOverrides)
            : <String, dynamic>{};
    return DeckSettings(
      userId: (json['user_id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      overrides: parsedOverrides,
      dailyNewCardsLimit: (json['daily_new_cards_limit'] as num?)?.toInt() ??
          (parsedOverrides['daily_new_cards_limit'] as num?)?.toInt(),
      dailyReviewsLimit: (json['daily_reviews_limit'] as num?)?.toInt() ??
          (parsedOverrides['daily_reviews_limit'] as num?)?.toInt(),
      desiredRetention: (json['desired_retention'] as num?)?.toDouble() ??
          (parsedOverrides['desired_retention'] as num?)?.toDouble(),
      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 1,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> mergedOverrides = <String, dynamic>{
      ...overrides,
      'daily_new_cards_limit': dailyNewCardsLimit,
      'daily_reviews_limit': dailyReviewsLimit,
      'desired_retention': desiredRetention,
    };
    return <String, dynamic>{
      'user_id': userId,
      'deck_id': deckId,
      'overrides': mergedOverrides,
      'daily_new_cards_limit': dailyNewCardsLimit,
      'daily_reviews_limit': dailyReviewsLimit,
      'desired_retention': desiredRetention,
      'is_favorite': isFavorite,
      'display_order': displayOrder,
    };
  }
}

class DeckCollaborator {
  const DeckCollaborator({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String deckId;
  final String userId;
  final String role; // 'viewer' | 'editor'
  final String? createdAt;

  factory DeckCollaborator.fromJson(Map<String, dynamic> json) {
    final String deckId = (json['deck_id'] ?? '').toString();
    final String userId = (json['user_id'] ?? '').toString();
    return DeckCollaborator(
      id: (json['id'] ?? '$deckId:$userId').toString(),
      deckId: deckId,
      userId: userId,
      role: (json['role'] ?? 'viewer').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'deck_id': deckId,
        'user_id': userId,
        'role': role,
        'created_at': createdAt,
      };
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

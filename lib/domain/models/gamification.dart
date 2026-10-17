/// Gamification profile, badges, session XP results, and leaderboard models.
///
/// Mirrors `src/lib/services/gamification-service.ts` from `app-flashi`.
class GamificationProfile {
  const GamificationProfile({
    required this.userId,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.streakFreezesAvailable,
    this.lastActivityDate,
  });

  final String userId;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int streakFreezesAvailable;
  final String? lastActivityDate;

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      userId: json['user_id']?.toString() ?? '',
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      streakFreezesAvailable:
          (json['streak_freezes_available'] as num?)?.toInt() ?? 0,
      lastActivityDate: json['last_activity_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'total_xp': totalXp,
      'level': level,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'streak_freezes_available': streakFreezesAvailable,
      'last_activity_date': lastActivityDate,
    };
  }
}

/// Definition of an achievable gamification badge.
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String iconUrl;
  final String category;

  factory BadgeDefinition.fromJson(Map<String, dynamic> json) {
    return BadgeDefinition(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'category': category,
    };
  }
}

/// User-unlocked badge record with optional joined [badge] definition.
class UserBadge {
  const UserBadge({
    required this.id,
    required this.badgeId,
    required this.unlockedAt,
    this.badge,
  });

  final String id;
  final String badgeId;
  final String unlockedAt;
  final BadgeDefinition? badge;

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    final dynamic nestedBadge = json['badge'] ?? json['badges_definition'];
    return UserBadge(
      id: json['id']?.toString() ?? '',
      badgeId: json['badge_id']?.toString() ?? '',
      unlockedAt:
          json['unlocked_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      badge: nestedBadge is Map<String, dynamic>
          ? BadgeDefinition.fromJson(nestedBadge)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'badge_id': badgeId,
      'unlocked_at': unlockedAt,
      if (badge != null) 'badge': badge!.toJson(),
    };
  }
}

/// Result returned when syncing confirmed study session XP.
class SessionXpResult {
  const SessionXpResult({
    required this.totalXp,
    required this.newLevel,
    required this.levelUp,
    required this.newStreak,
    required this.streakUpdated,
    this.xpGained = 0,
    this.queued = false,
  });

  final int totalXp;
  final int newLevel;
  final bool levelUp;
  final int newStreak;
  final bool streakUpdated;
  final int xpGained;
  final bool queued;

  factory SessionXpResult.fromJson(Map<String, dynamic> json) {
    return SessionXpResult(
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      newLevel: (json['new_level'] as num?)?.toInt() ?? 1,
      levelUp: json['level_up'] == true,
      newStreak: (json['new_streak'] as num?)?.toInt() ?? 0,
      streakUpdated: json['streak_updated'] == true,
      xpGained: (json['xp_gained'] as num?)?.toInt() ?? 0,
      queued: json['queued'] == true,
    );
  }
}

/// Entry in the global XP leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final int totalXp;
  final int level;
  final int currentStreak;
  final String? displayName;
  final String? avatarUrl;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final dynamic profiles = json['profiles'];
    final Map<String, dynamic>? profileMap = profiles is List && profiles.isNotEmpty
        ? (profiles.first as Map<String, dynamic>?)
        : (profiles is Map<String, dynamic> ? profiles : null);

    return LeaderboardEntry(
      userId: json['user_id']?.toString() ?? '',
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      displayName:
          json['display_name']?.toString() ?? profileMap?['display_name']?.toString(),
      avatarUrl:
          json['avatar_url']?.toString() ?? profileMap?['avatar_url']?.toString(),
    );
  }
}

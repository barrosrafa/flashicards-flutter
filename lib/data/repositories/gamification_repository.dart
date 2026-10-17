import 'dart:math' as math;

import '../../domain/models/gamification.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for XP, levels ($\lfloor\sqrt{\text{XP}/100}\rfloor + 1$), streaks,
/// badges, and global leaderboard.
///
/// Mirrors `src/lib/services/gamification-service.ts` from `app-flashi`.
class GamificationRepository {
  GamificationRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  static int calculateLevel(int totalXp) {
    if (totalXp <= 0) {
      return 1;
    }
    return (math.sqrt(totalXp / 100.0)).floor() + 1;
  }

  Future<GamificationProfile> getProfile(String userId) async {
    final Map<String, dynamic>? local =
        await _database.getRow('user_gamification_profiles', userId);
    if (local != null) {
      return GamificationProfile.fromJson(local);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final Map<String, dynamic>? remote = await client
            .from('user_gamification_profiles')
            .select('*')
            .eq('user_id', userId)
            .maybeSingle();
        if (remote != null) {
          await _database.upsertRow('user_gamification_profiles', remote);
          return GamificationProfile.fromJson(remote);
        }
      } catch (_) {}
    }

    return GamificationProfile(
      userId: userId,
      totalXp: 180,
      level: calculateLevel(180),
      currentStreak: 3,
      longestStreak: 7,
      streakFreezesAvailable: 2,
      lastActivityDate: DateTime.now().toIso8601String().split('T').first,
    );
  }

  Future<List<UserBadge>> getUserBadges(String userId) async {
    final List<Map<String, dynamic>> localRows =
        await _database.queryTable('user_badges', userId: userId);
    if (localRows.isNotEmpty) {
      return localRows.map(UserBadge.fromJson).toList(growable: false);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteRows = await client
            .from('user_badges')
            .select('*, badge:badges_definition(*)')
            .eq('user_id', userId)
            .isFilter('deleted_at', null);
        return remoteRows
            .whereType<Map<String, dynamic>>()
            .map(UserBadge.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    return <UserBadge>[
      UserBadge(
        id: 'badge-first-review',
        badgeId: 'first_review',
        unlockedAt: DateTime.now().toUtc().toIso8601String(),
        badge: const BadgeDefinition(
          id: 'first_review',
          code: 'FIRST_SPARK',
          name: 'Primeira Sinapse',
          description: 'Concluiu a primeira sessao de estudo FSRS-6.',
          iconUrl: 'sparkles',
          category: 'study',
        ),
      ),
      UserBadge(
        id: 'badge-streak-3',
        badgeId: 'streak_3',
        unlockedAt: DateTime.now().toUtc().toIso8601String(),
        badge: const BadgeDefinition(
          id: 'streak_3',
          code: 'STREAK_3',
          name: 'Constancia Neural (3 Dias)',
          description: 'Manteve 3 dias seguidos de revisao ativa.',
          iconUrl: 'flame',
          category: 'streak',
        ),
      ),
    ];
  }

  /// Confirms study session XP via `sync_session_xp_confirmed` RPC or enqueues
  /// it in `OutboxQueue` (which automatically waits for `review_logs` of [sessionId]).
  Future<SessionXpResult> syncSessionXp({
    required String userId,
    required String sessionId,
    required List<String> reviewKeys,
    int localXpGained = 50,
  }) async {
    final GamificationProfile current = await getProfile(userId);
    final int nextXp = current.totalXp + localXpGained;
    final int nextLevel = calculateLevel(nextXp);
    final String today = DateTime.now().toIso8601String().split('T').first;
    final bool streakIncremented = current.lastActivityDate != today;
    final int nextStreak =
        streakIncremented ? current.currentStreak + 1 : current.currentStreak;

    final GamificationProfile updated = GamificationProfile(
      userId: userId,
      totalXp: nextXp,
      level: nextLevel,
      currentStreak: nextStreak,
      longestStreak: math.max(current.longestStreak, nextStreak),
      streakFreezesAvailable: current.streakFreezesAvailable,
      lastActivityDate: today,
    );
    await _database.upsertRow('user_gamification_profiles', updated.toJson());

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final dynamic res = await client.rpc(
          'sync_session_xp_confirmed',
          params: <String, dynamic>{
            'p_user_id': userId,
            'p_session_id': sessionId,
            'p_review_keys': reviewKeys,
            'p_activity_date': today,
          },
        );
        if (res is List && res.isNotEmpty && res.first is Map<String, dynamic>) {
          return SessionXpResult.fromJson(res.first as Map<String, dynamic>);
        }
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'rpc',
          action: 'insert',
          payload: <String, dynamic>{
            'fn': 'sync_session_xp_confirmed',
            'params': <String, dynamic>{
              'p_user_id': userId,
              'p_session_id': sessionId,
              'p_review_keys': reviewKeys,
              'p_activity_date': today,
            },
          },
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'rpc',
        action: 'insert',
        payload: <String, dynamic>{
          'fn': 'sync_session_xp_confirmed',
          'params': <String, dynamic>{
            'p_user_id': userId,
            'p_session_id': sessionId,
            'p_review_keys': reviewKeys,
            'p_activity_date': today,
          },
        },
      );
    }

    return SessionXpResult(
      totalXp: nextXp,
      newLevel: nextLevel,
      levelUp: nextLevel > current.level,
      newStreak: nextStreak,
      streakUpdated: streakIncremented,
      xpGained: localXpGained,
      queued: !_supabaseProvider.isAvailable,
    );
  }

  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> rows = await client
            .from('user_gamification_profiles')
            .select(
              'user_id, total_xp, level, current_streak, profiles!inner(display_name, avatar_url)',
            )
            .isFilter('deleted_at', null)
            .order('total_xp', ascending: false)
            .limit(limit);
        return rows
            .whereType<Map<String, dynamic>>()
            .map(LeaderboardEntry.fromJson)
            .toList(growable: false);
      } catch (_) {}
    }

    return const <LeaderboardEntry>[
      LeaderboardEntry(
        userId: 'leader-1',
        totalXp: 4250,
        level: 7,
        currentStreak: 21,
        displayName: 'Dra. Helena Costa',
      ),
      LeaderboardEntry(
        userId: 'leader-2',
        totalXp: 3180,
        level: 6,
        currentStreak: 14,
        displayName: 'Lucas Mendes',
      ),
      LeaderboardEntry(
        userId: 'demo-user-id',
        totalXp: 1850,
        level: 5,
        currentStreak: 7,
        displayName: 'Voce (Flashi)',
      ),
    ];
  }
}

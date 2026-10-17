import 'app_database.dart';

/// Enforces strict local storage isolation between authenticated user accounts.
///
/// Mirrors `ensureLocalUserScope` in `src/lib/local/user-scope.ts` from `app-flashi`.
class LocalUserScope {
  LocalUserScope({
    FlashiLocalDatabase? database,
  }) : _database = database ?? FlashiLocalDatabase.instance;

  final FlashiLocalDatabase _database;
  static const String _scopeKey = 'active_user_id';

  /// Verifies that the local database belongs to [userId]. If a different user
  /// was previously cached on this device, purges all local tables and outbox.
  Future<void> ensureScope(String userId) async {
    if (userId.isEmpty) {
      return;
    }
    final String? previousUserId = await _database.getSyncMeta(_scopeKey);
    if (previousUserId != null &&
        previousUserId.isNotEmpty &&
        previousUserId != userId) {
      await _database.clearAllUserData();
    }
    await _database.setSyncMeta(_scopeKey, userId);
  }

  /// Clears the active user scope and wipes local cache on explicit sign-out.
  Future<void> clearScope() async {
    await _database.clearAllUserData();
  }
}

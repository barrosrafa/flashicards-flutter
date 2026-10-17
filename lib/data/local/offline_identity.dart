import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the last authenticated user identity in secure storage so the app
/// can boot and study offline without an active network handshake.
///
/// Mirrors `src/lib/auth/offline-identity.ts` from `app-flashi`.
class OfflineIdentity {
  const OfflineIdentity({
    required this.userId,
    required this.email,
    required this.lastVerifiedAtIso,
  });

  final String userId;
  final String email;
  final String lastVerifiedAtIso;
}

class OfflineIdentityStore {
  OfflineIdentityStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  OfflineIdentity? _memoryFallback;

  static const String _keyUserId = 'flashi.offline.user_id';
  static const String _keyEmail = 'flashi.offline.email';
  static const String _keyVerifiedAt = 'flashi.offline.verified_at';

  Future<void> saveIdentity({
    required String userId,
    required String email,
  }) async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    _memoryFallback = OfflineIdentity(
      userId: userId,
      email: email,
      lastVerifiedAtIso: nowIso,
    );
    try {
      await _storage.write(key: _keyUserId, value: userId);
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyVerifiedAt, value: nowIso);
    } catch (_) {
      // Secure storage fallback in headless tests
    }
  }

  Future<OfflineIdentity?> readIdentity() async {
    try {
      final String? userId = await _storage.read(key: _keyUserId);
      final String? email = await _storage.read(key: _keyEmail);
      final String? verifiedAt = await _storage.read(key: _keyVerifiedAt);
      if (userId != null && userId.isNotEmpty) {
        return OfflineIdentity(
          userId: userId,
          email: email ?? '',
          lastVerifiedAtIso:
              verifiedAt ?? DateTime.now().toUtc().toIso8601String(),
        );
      }
    } catch (_) {
      // Ignore secure storage error in test environments
    }
    return _memoryFallback;
  }

  Future<void> clearIdentity() async {
    _memoryFallback = null;
    try {
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyVerifiedAt);
    } catch (_) {}
  }
}

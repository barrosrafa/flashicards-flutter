import '../../domain/models/user_profile.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for user profile (`profiles`) and global study settings (`study_settings`).
///
/// Mirrors `src/lib/services/profile-service.ts` from `app-flashi`.
class ProfileRepository {
  ProfileRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  Future<ProfileData> getProfileData({
    required String userId,
    required String email,
  }) async {
    final Map<String, dynamic>? localProfile =
        await _database.getRow('profiles', userId);
    final Map<String, dynamic>? localStudy =
        await _database.getRow('study_settings', userId);

    UserProfile profile = localProfile != null
        ? UserProfile.fromJson(localProfile)
        : UserProfile(
            id: userId,
            displayName: email.split('@').first,
            locale: 'pt-BR',
            timezone: 'America/Sao_Paulo',
            theme: 'dark',
            onboardingCompleted: true,
          );

    StudySettings study = localStudy != null
        ? StudySettings.fromJson(localStudy)
        : StudySettings.defaults();

    final client = _supabaseProvider.client;
    if (client != null && (localProfile == null || localStudy == null)) {
      try {
        final Map<String, dynamic>? remoteProfile = await client
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .maybeSingle();
        if (remoteProfile != null) {
          await _database.upsertRow('profiles', remoteProfile);
          profile = UserProfile.fromJson(remoteProfile);
        }

        final Map<String, dynamic>? remoteStudy = await client
            .from('study_settings')
            .select('*')
            .eq('user_id', userId)
            .maybeSingle();
        if (remoteStudy != null) {
          await _database.upsertRow('study_settings', remoteStudy);
          study = StudySettings.fromJson(remoteStudy);
        }
      } catch (_) {}
    }

    return ProfileData(
      email: email,
      profile: profile,
      study: study,
    );
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      ...profile.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _database.upsertRow('profiles', payload);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.from('profiles').upsert(payload);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'profiles',
          action: 'update',
          payload: payload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'profiles',
        action: 'update',
        payload: payload,
      );
    }
    return profile;
  }

  Future<StudySettings> updateStudySettings({
    required String userId,
    required StudySettings settings,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'user_id': userId,
      ...settings.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _database.upsertRow('study_settings', payload);

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.from('study_settings').upsert(payload);
      } catch (_) {
        await _outboxQueue.enqueueMutation(
          tableName: 'study_settings',
          action: 'update',
          payload: payload,
        );
      }
    } else {
      await _outboxQueue.enqueueMutation(
        tableName: 'study_settings',
        action: 'update',
        payload: payload,
      );
    }
    return settings;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env_config.dart';

/// Singleton provider for the Supabase client that gracefully handles offline/demo
/// environments when `SUPABASE_URL` is not configured.
class SupabaseClientProvider {
  SupabaseClientProvider._();

  static final SupabaseClientProvider instance = SupabaseClientProvider._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (!EnvConfig.isSupabaseConfigured) {
      return;
    }
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      _initialized = true;
    } catch (_) {
      // Already initialized or running in offline test environment
    }
  }

  bool get isAvailable => _initialized && EnvConfig.isSupabaseConfigured;

  SupabaseClient? get client {
    if (!isAvailable) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => client?.auth.currentUser;

  String? get currentUserId => currentUser?.id;
}

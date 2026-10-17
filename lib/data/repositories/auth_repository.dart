import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exceptions.dart';
import '../local/local_user_scope.dart';
import '../local/offline_identity.dart';
import '../remote/supabase_client_provider.dart';

class SignUpOutcome {
  const SignUpOutcome({
    required this.user,
    required this.session,
    required this.requiresEmailConfirmation,
  });

  final User? user;
  final Session? session;
  final bool requiresEmailConfirmation;
}

/// Repository handling authentication, OAuth PKCE deep links, password recovery,
/// and offline identity bootstrapping.
///
/// Mirrors `src/lib/supabase/client.ts` and `src/lib/auth/offline-identity.ts` from `app-flashi`.
class AuthRepository extends ChangeNotifier {
  AuthRepository({
    SupabaseClientProvider? supabaseProvider,
    OfflineIdentityStore? offlineIdentityStore,
    LocalUserScope? localUserScope,
  })  : _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance,
        _offlineIdentityStore = offlineIdentityStore ?? OfflineIdentityStore(),
        _localUserScope = localUserScope ?? LocalUserScope() {
    _initAuthListener();
  }

  final SupabaseClientProvider _supabaseProvider;
  final OfflineIdentityStore _offlineIdentityStore;
  final LocalUserScope _localUserScope;
  StreamSubscription<AuthState>? _authSubscription;

  String? _userId;
  String? _userEmail;
  bool _isDemoSession = false;

  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isAuthenticated => _userId != null && _userId!.isNotEmpty;
  bool get isDemoSession => _isDemoSession;

  void _initAuthListener() {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client != null) {
      _authSubscription = client.auth.onAuthStateChange.listen((AuthState data) {
        final Session? session = data.session;
        if (session?.user != null) {
          _userId = session!.user.id;
          _userEmail = session.user.email ?? '';
          _isDemoSession = false;
          _localUserScope.ensureScope(_userId!);
          _offlineIdentityStore.saveIdentity(
            userId: _userId!,
            email: _userEmail!,
          );
        } else if (data.event == AuthChangeEvent.signedOut) {
          _userId = null;
          _userEmail = null;
          _isDemoSession = false;
        }
        notifyListeners();
      });
    }
  }

  /// Restores active Supabase session or falls back to cached offline identity.
  Future<void> bootstrapSession() async {
    final User? remoteUser = _supabaseProvider.currentUser;
    if (remoteUser != null) {
      _userId = remoteUser.id;
      _userEmail = remoteUser.email ?? '';
      _isDemoSession = false;
      await _localUserScope.ensureScope(remoteUser.id);
      await _offlineIdentityStore.saveIdentity(
        userId: remoteUser.id,
        email: _userEmail!,
      );
      notifyListeners();
      return;
    }

    final OfflineIdentity? cached = await _offlineIdentityStore.readIdentity();
    if (cached != null && cached.userId.isNotEmpty) {
      _userId = cached.userId;
      _userEmail = cached.email;
      _isDemoSession = cached.userId == 'demo-user-id';
      await _localUserScope.ensureScope(cached.userId);
      notifyListeners();
    }
  }

  /// Signs in with email and password.
  /// If Supabase is not configured in environment, activates a local offline/demo session.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client == null) {
      await startDemoSession(email: email);
      return;
    }

    final AuthResponse response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final User? user = response.user;
    if (user == null) {
      throw const UnauthenticatedException('Credenciais inválidas.');
    }
    _userId = user.id;
    _userEmail = user.email ?? email.trim();
    _isDemoSession = false;
    await _localUserScope.ensureScope(user.id);
    await _offlineIdentityStore.saveIdentity(
      userId: user.id,
      email: _userEmail!,
    );
    notifyListeners();
  }

  /// Registers a new user account with email, password, and display name.
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client == null) {
      await startDemoSession(email: email);
      return SignUpOutcome(
        user: null,
        session: null,
        requiresEmailConfirmation: false,
      );
    }

    final AuthResponse response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: <String, dynamic>{
        if (displayName != null && displayName.trim().isNotEmpty)
          'display_name': displayName.trim(),
      },
    );
    final User? user = response.user;
    final Session? session = response.session;
    final bool requiresEmailConfirmation = session == null;

    if (user != null) {
      _userId = user.id;
      _userEmail = user.email ?? email.trim();
      _isDemoSession = false;
      await _localUserScope.ensureScope(user.id);
      await _offlineIdentityStore.saveIdentity(
        userId: user.id,
        email: _userEmail!,
      );
      notifyListeners();
    }

    return SignUpOutcome(
      user: user,
      session: session,
      requiresEmailConfirmation: requiresEmailConfirmation,
    );
  }

  /// Initiates Google OAuth PKCE flow with native deep link callback `io.flashi.app://auth-callback`.
  Future<void> signInWithGoogle() async {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client == null) {
      await startDemoSession(email: 'demo@flashi.app');
      return;
    }

    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.flashi.app://auth-callback',
    );
  }

  /// Exchanges OAuth or recovery code/hash in deep link for active session.
  Future<void> exchangeCodeForSession(Uri uri) async {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client != null) {
      await client.auth.getSessionFromUrl(uri);
      final User? user = client.auth.currentUser;
      if (user != null) {
        _userId = user.id;
        _userEmail = user.email ?? '';
        _isDemoSession = false;
        await _localUserScope.ensureScope(_userId!);
        await _offlineIdentityStore.saveIdentity(
          userId: _userId!,
          email: _userEmail!,
        );
        notifyListeners();
      }
    }
  }

  /// Sends password recovery link to [email].
  Future<void> sendPasswordResetEmail(String email) async {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client == null) {
      return;
    }
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.flashi.app://auth-callback',
    );
  }

  /// Updates the current user's password after recovery deep link.
  Future<void> updatePassword(String newPassword) async {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client == null) {
      return;
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Starts a local offline/demo session explicitly when chosen by user.
  Future<void> startDemoSession({String email = 'demo@flashi.app'}) async {
    _userId = 'demo-user-id';
    _userEmail = email.trim().isEmpty ? 'demo@flashi.app' : email.trim();
    _isDemoSession = true;
    await _localUserScope.ensureScope(_userId!);
    await _offlineIdentityStore.saveIdentity(
      userId: _userId!,
      email: _userEmail!,
    );
    notifyListeners();
  }

  /// Signs out and purges local database scope.
  Future<void> signOut() async {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _userId = null;
    _userEmail = null;
    _isDemoSession = false;
    await _offlineIdentityStore.clearIdentity();
    await _localUserScope.clearScope();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

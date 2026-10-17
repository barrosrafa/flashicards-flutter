import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/widgets/aurora_scaffold.dart';

/// Screen that handles incoming deep links for OAuth PKCE and password recovery callbacks.
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processAuthCallback();
    });
  }

  Future<void> _processAuthCallback() async {
    final Uri uri = GoRouterState.of(context).uri;
    try {
      await ServiceLocator.instance.authRepository.exchangeCodeForSession(uri);
      if (!mounted) return;

      // Check if this was a password recovery callback
      final String? type = uri.queryParameters['type'] ??
          (uri.fragment.contains('type=recovery') ? 'recovery' : null);

      if (type == 'recovery') {
        context.go('/reset-password');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Falha ao autenticar: $e';
      });
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go('/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return AuroraScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_errorMessage != null) ...<Widget>[
              Icon(Icons.error_outline_rounded, color: colors.ratingAgain, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.ratingAgain),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Redirecionando para o login...',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ] else ...<Widget>[
              CircularProgressIndicator(color: colors.accentCyan),
              const SizedBox(height: 20),
              Text(
                'Validando credenciais...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

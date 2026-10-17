import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/validators.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/widgets/aurora_scaffold.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Password recovery request and reset screens (`/forgot-password` and `/reset-password`).
///
/// Mirrors `src/app/forgot-password/page.tsx` and `src/app/reset-password/page.tsx` from `app-flashi`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.isResetMode = false,
  });

  final bool isResetMode;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _sentSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isResetMode) {
        await ServiceLocator.instance.authRepository
            .updatePassword(_newPasswordController.text);
        if (!mounted) {
          return;
        }
        context.go('/dashboard');
      } else {
        await ServiceLocator.instance.authRepository
            .sendPasswordResetEmail(_emailController.text);
        if (!mounted) {
          return;
        }
        setState(() {
          _sentSuccess = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return AuroraScaffold(
      extendBody: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          widget.isResetMode ? 'Nova Senha' : 'Recuperar Senha',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlassBentoCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      widget.isResetMode
                          ? 'Defina sua nova senha'
                          : 'Redefinir acesso',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isResetMode
                          ? 'Escolha uma senha forte com pelo menos 8 caracteres.'
                          : 'Enviaremos um link seguro para redefinir sua senha.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (_sentSuccess)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.ratingGood.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Link de recuperacao enviado! Verifique sua caixa de entrada.',
                          style: TextStyle(color: colors.ratingGood),
                        ),
                      )
                    else if (widget.isResetMode)
                      FuturisticFormField(
                        label: 'Nova senha',
                        controller: _newPasswordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_reset_rounded,
                        validator: Validators.validatePassword,
                      )
                    else
                      FuturisticFormField(
                        label: 'E-mail da conta',
                        controller: _emailController,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                    const SizedBox(height: 20),
                    if (!_sentSuccess)
                      CyberPrimaryButton(
                        label: widget.isResetMode
                            ? 'Salvar Nova Senha'
                            : 'Enviar Link de Recuperacao',
                        isLoading: _isLoading,
                        fullWidth: true,
                        onPressed: _submit,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

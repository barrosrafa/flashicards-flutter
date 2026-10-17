import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/user_profile.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// User Profile, Global FSRS-6 Study Settings, Dark OLED / Light Theme toggle,
/// and `pt-BR`/`en`/`es` Localization switcher (`/profile`).
///
/// Mirrors `src/app/profile/page.tsx` from `app-flashi`.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _dailyNewLimit = 20;
  int _dailyReviewsLimit = 200;
  double _desiredRetention = 0.90;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final ProfileData data = await locator.profileRepository.getProfileData(
      userId: locator.activeUserId,
      email: locator.activeUserEmail,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _nameController.text = data.profile.displayName;
      _dailyNewLimit = data.study.dailyNewCardsLimit;
      _dailyReviewsLimit = data.study.dailyReviewsLimit;
      _desiredRetention = data.study.desiredRetention;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final ServiceLocator locator = ServiceLocator.instance;
      final String userId = locator.activeUserId;
      await locator.profileRepository.updateProfile(
        UserProfile(
          id: userId,
          displayName: _nameController.text.trim(),
          locale: locator.themeController.locale.languageCode,
          timezone: 'America/Sao_Paulo',
          theme: locator.themeController.isDarkMode ? 'dark' : 'light',
          onboardingCompleted: true,
        ),
      );
      await locator.profileRepository.updateStudySettings(
        userId: userId,
        settings: StudySettings(
          dailyNewCardsLimit: _dailyNewLimit,
          dailyReviewsLimit: _dailyReviewsLimit,
          desiredRetention: _desiredRetention,
          maximumIntervalDays: 36500,
          dayBoundaryHour: 4,
          autoPlayAudio: true,
          showNextIntervals: true,
          enableKeyboardShortcuts: true,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencias salvas e sincronizadas!')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final ServiceLocator locator = ServiceLocator.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: <Widget>[
        Text(
          'Perfil & Ajustes FSRS-6',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),

        // Quick Links Row: Analytics, Gamification, Exams, Media
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: <Widget>[
            _QuickNavCard(
              icon: Icons.insights_rounded,
              title: 'Telemetria & Pesos',
              onTap: () => context.go('/analytics'),
            ),
            _QuickNavCard(
              icon: Icons.emoji_events_rounded,
              title: 'XP & Ranking',
              onTap: () => context.go('/gamification'),
            ),
            _QuickNavCard(
              icon: Icons.timer_rounded,
              title: 'Modo Prova',
              onTap: () => context.go('/exams'),
            ),
            _QuickNavCard(
              icon: Icons.perm_media_rounded,
              title: 'Galeria de Midia',
              onTap: () => context.go('/media'),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Theme & Localization Card
        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FuturisticFormField(
                label: 'Nome de Exibicao',
                controller: _nameController,
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: locator.themeController,
                builder: (BuildContext context, _) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tema Spatial Aurora Dark (OLED)'),
                    subtitle: Text(
                      'Desative para usar o modo claro Alabaster Daylight',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    value: locator.themeController.isDarkMode,
                    onChanged: (_) => locator.themeController.toggleTheme(),
                  );
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <({String code, String label})>[
                  (code: 'pt-BR', label: 'Portugues (BR)'),
                  (code: 'en', label: 'English'),
                  (code: 'es', label: 'Espanol'),
                ].map((({String code, String label}) item) {
                  return ChoiceChip(
                    label: Text(item.label),
                    selected: locator.themeController.locale.languageCode ==
                        item.code.split('-').first,
                    onSelected: (_) =>
                        locator.themeController.setLocaleCode(item.code),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Global FSRS-6 Settings
        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Parametros Globais FSRS-6',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('Novos cartoes por dia: $_dailyNewLimit'),
              Slider(
                value: _dailyNewLimit.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                onChanged: (double v) =>
                    setState(() => _dailyNewLimit = v.round()),
              ),
              Text('Maximo de revisoes diarias: $_dailyReviewsLimit'),
              Slider(
                value: _dailyReviewsLimit.toDouble(),
                min: 20,
                max: 500,
                divisions: 24,
                onChanged: (double v) =>
                    setState(() => _dailyReviewsLimit = v.round()),
              ),
              Text(
                'Retencao Desejada: ${(_desiredRetention * 100).round()}%',
              ),
              Slider(
                value: _desiredRetention,
                min: 0.75,
                max: 0.97,
                divisions: 22,
                onChanged: (double v) => setState(() => _desiredRetention = v),
              ),
              const SizedBox(height: 12),
              CyberPrimaryButton(
                label: 'Salvar Configuracoes',
                icon: Icons.save_rounded,
                isLoading: _saving,
                fullWidth: true,
                onPressed: _saveSettings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: colors.ratingAgain.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () async {
            await locator.authRepository.signOut();
            if (!context.mounted) {
              return;
            }
            context.go('/');
          },
          icon: Icon(Icons.logout_rounded, color: colors.ratingAgain),
          label: Text(
            'Encerrar Sessao e Limpar Cache Local',
            style: TextStyle(color: colors.ratingAgain),
          ),
        ),
      ],
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  const _QuickNavCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    return GlassBentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, color: colors.accentCyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

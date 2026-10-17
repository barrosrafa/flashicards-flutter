import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/haptics_helper.dart';
import '../theme/flashi_color_tokens.dart';
import 'aurora_scaffold.dart';

/// Spatial Aurora floating glass bottom navigation dock for the 5 primary mobile
/// hubs: Home (`/dashboard`), Decks (`/decks`), Study (`/study`), AI & Tools (`/tools`),
/// and Profile/Analytics (`/profile`).
class AppShellNavigation extends StatelessWidget {
  const AppShellNavigation({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  final Widget child;
  final String currentLocation;

  int _resolveSelectedIndex(String location) {
    if (location.startsWith('/decks') || location.startsWith('/explore')) {
      return 1;
    }
    if (location.startsWith('/study')) {
      return 2;
    }
    if (location.startsWith('/tools') ||
        location.startsWith('/ingest') ||
        location.startsWith('/import') ||
        location.startsWith('/anki') ||
        location.startsWith('/occlusion') ||
        location.startsWith('/templates') ||
        location.startsWith('/search')) {
      return 3;
    }
    if (location.startsWith('/profile') ||
        location.startsWith('/analytics') ||
        location.startsWith('/gamification') ||
        location.startsWith('/exams') ||
        location.startsWith('/media')) {
      return 4;
    }
    return 0;
  }

  void _onSelectIndex(BuildContext context, int index) {
    HapticsHelper.selectionClick();
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/decks');
      case 2:
        context.go('/study');
      case 3:
        context.go('/tools');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int selectedIndex = _resolveSelectedIndex(currentLocation);

    return AuroraScaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: colors.surfaceGlassPrimary,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.borderSpecular),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _DockNavItem(
                      icon: Icons.grid_view_rounded,
                      label: l10n.tr('nav.dashboard', fallback: 'Inicio'),
                      selected: selectedIndex == 0,
                      onTap: () => _onSelectIndex(context, 0),
                    ),
                    _DockNavItem(
                      icon: Icons.layers_rounded,
                      label: l10n.tr('nav.decks', fallback: 'Decks'),
                      selected: selectedIndex == 1,
                      onTap: () => _onSelectIndex(context, 1),
                    ),
                    _CenterStudyOrbButton(
                      selected: selectedIndex == 2,
                      onTap: () => _onSelectIndex(context, 2),
                    ),
                    _DockNavItem(
                      icon: Icons.auto_awesome_rounded,
                      label: l10n.tr('nav.tools', fallback: 'IA & Lab'),
                      selected: selectedIndex == 3,
                      onTap: () => _onSelectIndex(context, 3),
                    ),
                    _DockNavItem(
                      icon: Icons.insights_rounded,
                      label: l10n.tr('nav.profile', fallback: 'Perfil'),
                      selected: selectedIndex == 4,
                      onTap: () => _onSelectIndex(context, 4),
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

class _DockNavItem extends StatelessWidget {
  const _DockNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final Color color = selected ? colors.accentCyan : colors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterStudyOrbButton extends StatelessWidget {
  const _CenterStudyOrbButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: colors.primaryAuroraGradient,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.accentCyan.withValues(alpha: selected ? 0.55 : 0.30),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.bolt_rounded,
          color: Color(0xFF05070E),
          size: 26,
        ),
      ),
    );
  }
}

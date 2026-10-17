import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/core/widgets/app_shell_navigation.dart';
import '../../ui/features/analytics/analytics_screen.dart';
import '../../ui/features/auth/auth_callback_screen.dart';
import '../../ui/features/auth/forgot_password_screen.dart';
import '../../ui/features/auth/login_screen.dart';
import '../../ui/features/auth/register_screen.dart';
import '../../ui/features/dashboard/dashboard_screen.dart';
import '../../ui/features/decks/deck_detail_screen.dart';
import '../../ui/features/decks/decks_list_screen.dart';
import '../../ui/features/exams/exam_scheduler_screen.dart';
import '../../ui/features/gamification/gamification_screen.dart';
import '../../ui/features/imports_exports/ai_ingestion_screen.dart';
import '../../ui/features/imports_exports/anki_transfer_screen.dart';
import '../../ui/features/imports_exports/file_import_screen.dart';
import '../../ui/features/landing/landing_screen.dart';
import '../../ui/features/media/media_gallery_screen.dart';
import '../../ui/features/occlusion/image_occlusion_editor_screen.dart';
import '../../ui/features/onboarding/onboarding_wizard_screen.dart';
import '../../ui/features/profile_settings/profile_settings_screen.dart';
import '../../ui/features/search/semantic_search_screen.dart';
import '../../ui/features/study/study_session_screen.dart';
import '../../ui/features/templates/templates_manager_screen.dart';
import '../../ui/features/tools/tools_hub_screen.dart';
import '../di/service_locator.dart';

/// Declarative `GoRouter` configuration mapping all `app-flashi` Next.js App Router
/// routes and OAuth PKCE deep links (`io.flashi.app://auth-callback`).
class AppRouter {
  const AppRouter._();

  static GoRouter createRouter() {
    final ServiceLocator locator = ServiceLocator.instance;

    return GoRouter(
      initialLocation:
          locator.authRepository.isAuthenticated ? '/dashboard' : '/',
      refreshListenable: locator.authRepository,
      redirect: (BuildContext context, GoRouterState state) {
        final bool isAuth = locator.authRepository.isAuthenticated;
        final String path = state.uri.path;
        final bool isPublicRoute = path == '/' ||
            path == '/login' ||
            path == '/register' ||
            path == '/forgot-password' ||
            path == '/reset-password' ||
            path == '/auth-callback';

        if (!isAuth && !isPublicRoute) {
          return '/login';
        }
        if (isAuth && (path == '/login' || path == '/register')) {
          return '/dashboard';
        }
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) =>
              const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (BuildContext context, GoRouterState state) =>
              const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (BuildContext context, GoRouterState state) =>
              const ForgotPasswordScreen(isResetMode: true),
        ),
        GoRoute(
          path: '/auth-callback',
          builder: (BuildContext context, GoRouterState state) =>
              const AuthCallbackScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (BuildContext context, GoRouterState state) =>
              const OnboardingWizardScreen(),
        ),
        ShellRoute(
          builder: (
            BuildContext context,
            GoRouterState state,
            Widget child,
          ) {
            return AppShellNavigation(
              currentLocation: state.uri.path,
              child: child,
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const DashboardScreen(),
            ),
            GoRoute(
              path: '/decks',
              builder: (BuildContext context, GoRouterState state) =>
                  const DecksListScreen(),
            ),
            GoRoute(
              path: '/decks/:deckId',
              builder: (BuildContext context, GoRouterState state) {
                final String deckId = state.pathParameters['deckId'] ?? '';
                return DeckDetailScreen(deckId: deckId);
              },
            ),
            GoRoute(
              path: '/explore',
              builder: (BuildContext context, GoRouterState state) =>
                  const DecksListScreen(initialMarketplaceTab: true),
            ),
            GoRoute(
              path: '/study',
              builder: (BuildContext context, GoRouterState state) {
                final String? deckId = state.uri.queryParameters['deckId'];
                return StudySessionScreen(deckId: deckId);
              },
            ),
            GoRoute(
              path: '/tools',
              builder: (BuildContext context, GoRouterState state) =>
                  const ToolsHubScreen(),
            ),
            GoRoute(
              path: '/ingest',
              builder: (BuildContext context, GoRouterState state) =>
                  const AiIngestionScreen(),
            ),
            GoRoute(
              path: '/import',
              builder: (BuildContext context, GoRouterState state) =>
                  const FileImportScreen(),
            ),
            GoRoute(
              path: '/anki',
              builder: (BuildContext context, GoRouterState state) =>
                  const AnkiTransferScreen(),
            ),
            GoRoute(
              path: '/occlusion',
              builder: (BuildContext context, GoRouterState state) =>
                  const ImageOcclusionEditorScreen(),
            ),
            GoRoute(
              path: '/templates',
              builder: (BuildContext context, GoRouterState state) =>
                  const TemplatesManagerScreen(),
            ),
            GoRoute(
              path: '/search',
              builder: (BuildContext context, GoRouterState state) =>
                  const SemanticSearchScreen(),
            ),
            GoRoute(
              path: '/exams',
              builder: (BuildContext context, GoRouterState state) =>
                  const ExamSchedulerScreen(),
            ),
            GoRoute(
              path: '/analytics',
              builder: (BuildContext context, GoRouterState state) =>
                  const AnalyticsScreen(),
            ),
            GoRoute(
              path: '/gamification',
              builder: (BuildContext context, GoRouterState state) =>
                  const GamificationScreen(),
            ),
            GoRoute(
              path: '/media',
              builder: (BuildContext context, GoRouterState state) =>
                  const MediaGalleryScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (BuildContext context, GoRouterState state) =>
                  const ProfileSettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

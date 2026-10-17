import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/env_config.dart';
import 'analytics_events.dart';
import 'privacy_sanitizer.dart';

/// Serviço central de observabilidade best-effort (Sentry + PostHog).
///
/// Falhas nos provedores de telemetria nunca bloqueiam fluxos de autenticação,
/// estudo, criação de cartões ou sincronização offline.
class ObservabilityService {
  ObservabilityService._();

  static final ObservabilityService instance = ObservabilityService._();

  Future<void> capture(
    String eventName, [
    Map<String, dynamic> properties = const {},
  ]) async {
    final sanitized = PrivacySanitizer.sanitizeMap(properties);
    if (!EnvConfig.posthogEnabled || EnvConfig.posthogProjectToken.isEmpty) {
      return;
    }
    try {
      await Posthog().capture(
        eventName: eventName,
        properties: sanitized.map((k, v) => MapEntry(k, v as Object)),
      );
    } catch (_) {
      // Best-effort: nunca propagar erro de telemetria para a UI.
    }
  }

  Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    Map<String, String>? tags,
    Map<String, dynamic>? extra,
  }) async {
    if (EnvConfig.sentryDsn.isEmpty) return;
    try {
      final sanitizedExtra =
          extra != null ? PrivacySanitizer.sanitizeMap(extra) : null;
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          tags?.forEach(scope.setTag);
          sanitizedExtra?.forEach(scope.setContexts);
        },
      );
    } catch (_) {
      // Best-effort
    }
  }

  Future<void> identifyUser(String userId) async {
    try {
      if (EnvConfig.sentryDsn.isNotEmpty) {
        await Sentry.configureScope((scope) {
          scope.setUser(SentryUser(id: userId));
        });
      }
      if (EnvConfig.posthogEnabled && EnvConfig.posthogProjectToken.isNotEmpty) {
        await Posthog().identify(userId: userId);
      }
    } catch (_) {}
  }

  Future<void> resetAnalytics() async {
    try {
      if (EnvConfig.sentryDsn.isNotEmpty) {
        await Sentry.configureScope((scope) => scope.setUser(null));
      }
      if (EnvConfig.posthogEnabled && EnvConfig.posthogProjectToken.isNotEmpty) {
        await Posthog().reset();
      }
    } catch (_) {}
  }
}

/// Observer de navegação que emite `page_viewed` automaticamente a cada rota.
class FlashiRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _recordRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _recordRoute(newRoute);
  }

  void _recordRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      ObservabilityService.instance.capture(
        AnalyticsEvents.pageViewed,
        {'route': name},
      );
    }
  }
}

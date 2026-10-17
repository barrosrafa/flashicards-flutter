/// Catálogo estrito de eventos e utilitários de normalização equivalente a
/// `lib/observability/events.ts`.
class AnalyticsEvents {
  const AnalyticsEvents._();

  static const String pageViewed = 'page_viewed';
  static const String uiInteraction = 'ui_interaction';
  static const String clientError = 'client_error';
  static const String apiRequestStarted = 'api_request_started';
  static const String apiRequestCompleted = 'api_request_completed';
  static const String supabaseRequestCompleted = 'supabase_request_completed';
  static const String signupStarted = 'signup_started';
  static const String signupCompleted = 'signup_completed';
  static const String loginSucceeded = 'login_succeeded';
  static const String loginFailed = 'login_failed';
  static const String activationViewed = 'activation_viewed';
  static const String activationSubmitted = 'activation_submitted';
  static const String activationCompleted = 'activation_completed';
  static const String activationFailed = 'activation_failed';
  static const String syncStarted = 'sync_started';
  static const String syncCompleted = 'sync_completed';
  static const String syncFailed = 'sync_failed';
  static const String studySessionStarted = 'study_session_started';
  static const String cardRated = 'card_rated';
  static const String studySessionCompleted = 'study_session_completed';
  static const String deckCreated = 'deck_created';
  static const String cardCreated = 'card_created';
  static const String aiGenerationStarted = 'ai_generation_started';
  static const String aiGenerationCompleted = 'ai_generation_completed';
  static const String aiGenerationFailed = 'ai_generation_failed';
  static const String reviewQueued = 'review_queued';
  static const String reviewSent = 'review_sent';
  static const String reviewConfirmed = 'review_confirmed';
  static const String reviewFailed = 'review_failed';
  static const String outboxFlushStarted = 'outbox_flush_started';
  static const String outboxFlushCompleted = 'outbox_flush_completed';
  static const String outboxItemFailed = 'outbox_item_failed';

  static String weeklyMinutesBucket(Object? value) {
    final minutes = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (minutes == null || !minutes.isFinite) return 'none';
    if (minutes < 60) return '0-59';
    if (minutes < 180) return '60-179';
    if (minutes < 360) return '180-359';
    if (minutes < 600) return '360-599';
    if (minutes < 1200) return '600-1199';
    return '1200+';
  }

  static String normalizeErrorCode(Object? error) {
    final message = error?.toString() ?? 'UNKNOWN_ERROR';
    final match = RegExp(r'[A-Z][A-Z0-9_]{2,}').firstMatch(message);
    return match?.group(0) ?? 'UNKNOWN_ERROR';
  }
}

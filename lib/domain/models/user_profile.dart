/// User profile and study settings models.
///
/// Mirrors `src/lib/services/profile-service.ts` from `app-flashi`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.locale,
    required this.timezone,
    required this.theme,
    required this.onboardingCompleted,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String locale;
  final String timezone;
  final String theme;
  final bool onboardingCompleted;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      locale: json['locale']?.toString() ?? 'pt-BR',
      timezone: json['timezone']?.toString() ?? 'America/Sao_Paulo',
      theme: json['theme']?.toString() ?? 'dark',
      onboardingCompleted: json['onboarding_completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'locale': locale,
      'timezone': timezone,
      'theme': theme,
      'onboarding_completed': onboardingCompleted,
    };
  }
}

class StudySettings {
  const StudySettings({
    required this.dailyNewCardsLimit,
    required this.dailyReviewsLimit,
    required this.desiredRetention,
    required this.maximumIntervalDays,
    required this.dayBoundaryHour,
    required this.autoPlayAudio,
    required this.showNextIntervals,
    required this.enableKeyboardShortcuts,
  });

  final int dailyNewCardsLimit;
  final int dailyReviewsLimit;
  final double desiredRetention;
  final int maximumIntervalDays;
  final int dayBoundaryHour;
  final bool autoPlayAudio;
  final bool showNextIntervals;
  final bool enableKeyboardShortcuts;

  factory StudySettings.defaults() {
    return const StudySettings(
      dailyNewCardsLimit: 20,
      dailyReviewsLimit: 200,
      desiredRetention: 0.9,
      maximumIntervalDays: 36500,
      dayBoundaryHour: 4,
      autoPlayAudio: true,
      showNextIntervals: true,
      enableKeyboardShortcuts: true,
    );
  }

  factory StudySettings.fromJson(Map<String, dynamic> json) {
    return StudySettings(
      dailyNewCardsLimit:
          (json['daily_new_cards_limit'] as num?)?.toInt() ?? 20,
      dailyReviewsLimit:
          (json['daily_reviews_limit'] as num?)?.toInt() ?? 200,
      desiredRetention:
          (json['desired_retention'] as num?)?.toDouble() ?? 0.9,
      maximumIntervalDays:
          (json['maximum_interval_days'] as num?)?.toInt() ?? 36500,
      dayBoundaryHour: (json['day_boundary_hour'] as num?)?.toInt() ?? 4,
      autoPlayAudio: json['auto_play_audio'] != false,
      showNextIntervals: json['show_next_intervals'] != false,
      enableKeyboardShortcuts: json['enable_keyboard_shortcuts'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'daily_new_cards_limit': dailyNewCardsLimit,
      'daily_reviews_limit': dailyReviewsLimit,
      'desired_retention': desiredRetention,
      'maximum_interval_days': maximumIntervalDays,
      'day_boundary_hour': dayBoundaryHour,
      'auto_play_audio': autoPlayAudio,
      'show_next_intervals': showNextIntervals,
      'enable_keyboard_shortcuts': enableKeyboardShortcuts,
    };
  }
}

class ProfileData {
  const ProfileData({
    required this.email,
    required this.profile,
    required this.study,
  });

  final String email;
  final UserProfile profile;
  final StudySettings study;
}

class StudySettingsInput {
  const StudySettingsInput({
    required this.dailyNewCardsLimit,
    required this.dailyReviewsLimit,
    required this.desiredRetention,
    required this.maximumIntervalDays,
    required this.dayBoundaryHour,
    required this.autoPlayAudio,
    required this.showNextIntervals,
    required this.enableKeyboardShortcuts,
  });

  final int dailyNewCardsLimit;
  final int dailyReviewsLimit;
  final double desiredRetention;
  final int maximumIntervalDays;
  final int dayBoundaryHour;
  final bool autoPlayAudio;
  final bool showNextIntervals;
  final bool enableKeyboardShortcuts;
}

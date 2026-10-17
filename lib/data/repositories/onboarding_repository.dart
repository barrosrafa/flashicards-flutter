import '../../core/utils/crypto_utils.dart';
import '../../domain/models/learning_preferences.dart';
import '../../domain/models/note.dart';
import '../local/app_database.dart';
import '../remote/supabase_client_provider.dart';
import 'note_repository.dart';

/// Repository managing user onboarding state and starter deck provisioning.
///
/// Mirrors `src/lib/services/Onboarding-service.ts` from `app-flashi`.
class OnboardingRepository {
  OnboardingRepository({
    FlashiLocalDatabase? database,
    SupabaseClientProvider? supabaseProvider,
    NoteRepository? noteRepository,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance,
        _noteRepository = noteRepository ?? NoteRepository();

  final FlashiLocalDatabase _database;
  final SupabaseClientProvider _supabaseProvider;
  final NoteRepository _noteRepository;

  Future<OnboardingState> getOnboardingState(String userId) async {
    final Map<String, dynamic>? localProfile =
        await _database.getRow('profiles', userId);
    final List<Map<String, dynamic>> localDecks =
        await _database.queryTable('decks', userId: userId);

    if (localProfile != null) {
      return OnboardingState(
        onboardingCompleted: localProfile['onboarding_completed'] == true,
        deckCount: localDecks.length,
        starterDeckId:
            localDecks.isNotEmpty ? localDecks.first['id']?.toString() : null,
      );
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final Map<String, dynamic>? profileRow = await client
            .from('profiles')
            .select('onboarding_completed')
            .eq('id', userId)
            .maybeSingle();
        final List<dynamic> deckRows = await client
            .from('decks')
            .select('id')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: true)
            .limit(5);

        return OnboardingState(
          onboardingCompleted: profileRow?['onboarding_completed'] == true,
          deckCount: deckRows.length,
          starterDeckId: deckRows.isNotEmpty
              ? (deckRows.first as Map<String, dynamic>)['id']?.toString()
              : null,
        );
      } catch (_) {}
    }

    return OnboardingState(
      onboardingCompleted: localDecks.isNotEmpty,
      deckCount: localDecks.length,
      starterDeckId:
          localDecks.isNotEmpty ? localDecks.first['id']?.toString() : null,
    );
  }

  /// Completes onboarding, persists study limits, and provisions the starter deck
  /// with 5 curated cards for the user's chosen [LearningGoal].
  Future<ActivationResult> completeActivation({
    required String userId,
    required LearningPreferences preferences,
  }) async {
    final int newLimit = dailyMinutesToNewCardsLimit(preferences.dailyMinutes);
    final int reviewLimit =
        dailyMinutesToReviewsLimit(preferences.dailyMinutes);
    final LearningDraft draft =
        starterDraftByGoal[preferences.goal] ??
            starterDraftByGoal[LearningGoal.vestibular]!;

    final String nowIso = DateTime.now().toUtc().toIso8601String();
    String deckId = CryptoUtils.generateUuidV4();

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        await client.from('study_settings').upsert(<String, dynamic>{
          'user_id': userId,
          'daily_new_cards_limit': newLimit,
          'daily_reviews_limit': reviewLimit,
          'updated_at': nowIso,
        });

        final Map<String, dynamic> createdDeck = await client
            .from('decks')
            .insert(<String, dynamic>{
              'user_id': userId,
              'title': draft.title,
              'description': draft.description,
              'color': '#00F2FE',
              'icon': 'sparkles',
              'visibility': 'private',
              'position': 0,
            })
            .select('id')
            .single();
        deckId = createdDeck['id']?.toString() ?? deckId;

        await client.from('profiles').upsert(<String, dynamic>{
          'id': userId,
          'onboarding_completed': true,
          'updated_at': nowIso,
        });
      } catch (_) {}
    }

    // Persist locally for immediate offline availability
    await _database.upsertRow('decks', <String, dynamic>{
      'id': deckId,
      'user_id': userId,
      'title': draft.title,
      'description': draft.description,
      'color': '#00F2FE',
      'icon': 'sparkles',
      'visibility': 'private',
      'position': 0,
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    await _database.upsertRow('study_settings', <String, dynamic>{
      'user_id': userId,
      'daily_new_cards_limit': newLimit,
      'daily_reviews_limit': reviewLimit,
      'desired_retention': 0.9,
      'maximum_interval_days': 36500,
      'day_boundary_hour': 4,
      'auto_play_audio': true,
      'show_next_intervals': true,
      'enable_keyboard_shortcuts': true,
      'updated_at': nowIso,
    });

    await _database.upsertRow('profiles', <String, dynamic>{
      'id': userId,
      'display_name': 'Estudante Flashi',
      'locale': 'pt-BR',
      'timezone': 'America/Sao_Paulo',
      'theme': 'dark',
      'onboarding_completed': true,
      'updated_at': nowIso,
    });

    for (final StarterCardDraft card in draft.cards) {
      await _noteRepository.createNote(
        userId: userId,
        input: NoteInput(
          deckId: deckId,
          modelKind: 'basic',
          fieldValues: <String, String>{
            'front': card.front,
            'back': card.back,
          },
        ),
      );
    }

    return ActivationResult(
      deckId: deckId,
      createdStarterDeck: true,
    );
  }
}

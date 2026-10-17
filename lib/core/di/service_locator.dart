import '../../data/local/app_database.dart';
import '../../data/local/local_user_scope.dart';
import '../../data/local/offline_identity.dart';
import '../../data/local/outbox_queue.dart';
import '../../data/local/sync_engine.dart';
import '../../data/remote/edge_function_client.dart';
import '../../data/remote/mcp_external_client.dart';
import '../../data/remote/supabase_client_provider.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/anki_transfer_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/collaborator_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/deck_settings_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/ingestion_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/occlusion_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/optimizer_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/reference_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/repositories/socratic_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/template_repository.dart';
import '../../ui/core/theme/theme_controller.dart';

/// Application-wide dependency injection registry for Flashi.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late final FlashiLocalDatabase database = FlashiLocalDatabase.instance;
  late final OutboxQueue outboxQueue = OutboxQueue(database: database);
  late final LocalUserScope localUserScope = LocalUserScope(database: database);
  late final OfflineIdentityStore offlineIdentityStore = OfflineIdentityStore();
  late final SupabaseClientProvider supabaseProvider =
      SupabaseClientProvider.instance;
  late final EdgeFunctionClient edgeClient = EdgeFunctionClient.instance;
  late final McpExternalClient mcpClient = McpExternalClient(
    edgeClient: edgeClient,
  );

  late final SyncEngine syncEngine = SyncEngine(
    database: database,
    outboxQueue: outboxQueue,
    edgeClient: edgeClient,
    supabaseProvider: supabaseProvider,
  );

  late final ThemeController themeController = ThemeController();

  late final AuthRepository authRepository = AuthRepository(
    supabaseProvider: supabaseProvider,
    offlineIdentityStore: offlineIdentityStore,
    localUserScope: localUserScope,
  );

  late final NoteRepository noteRepository = NoteRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final OnboardingRepository onboardingRepository = OnboardingRepository(
    database: database,
    supabaseProvider: supabaseProvider,
    noteRepository: noteRepository,
  );

  late final DeckRepository deckRepository = DeckRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final DeckSettingsRepository deckSettingsRepository =
      DeckSettingsRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final CollaboratorRepository collaboratorRepository =
      CollaboratorRepository(
    database: database,
    supabaseProvider: supabaseProvider,
  );

  late final CardRepository cardRepository = CardRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final StudyRepository studyRepository = StudyRepository(
    database: database,
    outboxQueue: outboxQueue,
    edgeClient: edgeClient,
    supabaseProvider: supabaseProvider,
  );

  late final DashboardRepository dashboardRepository = DashboardRepository(
    deckRepository: deckRepository,
    cardRepository: cardRepository,
    studyRepository: studyRepository,
  );

  late final MediaRepository mediaRepository = MediaRepository(
    database: database,
    supabaseProvider: supabaseProvider,
  );

  late final OcclusionRepository occlusionRepository = OcclusionRepository(
    database: database,
    supabaseProvider: supabaseProvider,
  );

  late final SearchRepository searchRepository = SearchRepository(
    database: database,
    edgeClient: edgeClient,
    supabaseProvider: supabaseProvider,
  );

  late final IngestionRepository ingestionRepository = IngestionRepository(
    database: database,
    edgeClient: edgeClient,
    supabaseProvider: supabaseProvider,
    noteRepository: noteRepository,
  );

  late final ImportRepository importRepository = ImportRepository(
    edgeClient: edgeClient,
    supabaseProvider: supabaseProvider,
    noteRepository: noteRepository,
  );

  late final AnkiTransferRepository ankiTransferRepository =
      AnkiTransferRepository(
    database: database,
    edgeClient: edgeClient,
    supabaseProvider: supabaseProvider,
  );

  late final ExamRepository examRepository = ExamRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final GamificationRepository gamificationRepository =
      GamificationRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final SocraticRepository socraticRepository = SocraticRepository(
    database: database,
    edgeClient: edgeClient,
    supabaseProvider: supabaseProvider,
  );

  late final OptimizerRepository optimizerRepository = OptimizerRepository(
    database: database,
    edgeClient: edgeClient,
    supabaseProvider: supabaseProvider,
  );

  late final AnalyticsRepository analyticsRepository = AnalyticsRepository(
    database: database,
    supabaseProvider: supabaseProvider,
  );

  late final ProfileRepository profileRepository = ProfileRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final TemplateRepository templateRepository = TemplateRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final TagRepository tagRepository = TagRepository(
    database: database,
    outboxQueue: outboxQueue,
    supabaseProvider: supabaseProvider,
  );

  late final ReferenceRepository referenceRepository = ReferenceRepository(
    database: database,
    outboxQueue: outboxQueue,
  );

  String get activeUserId => authRepository.userId ?? 'demo-user-id';
  String get activeUserEmail => authRepository.userEmail ?? 'demo@flashi.app';
}

import '../../domain/models/analytics_summary.dart';
import '../local/app_database.dart';
import '../remote/edge_function_client.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for FSRS-6 21-weight personalization (`optimize-fsrs-params` Edge Function).
///
/// Mirrors `src/lib/services/optimizer-service.ts` from `app-flashi`.
class OptimizerRepository {
  OptimizerRepository({
    FlashiLocalDatabase? database,
    EdgeFunctionClient? edgeClient,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _edgeClient = edgeClient ?? EdgeFunctionClient.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final EdgeFunctionClient _edgeClient;
  final SupabaseClientProvider _supabaseProvider;

  static const int minRequiredReviews = 400;

  Future<FsrsOptimizationStatus> getStatus(String userId) async {
    final List<Map<String, dynamic>> localReviews =
        await _database.queryTable('review_logs', userId: userId);
    final List<Map<String, dynamic>> localRuns =
        await _database.queryTable('fsrs_optimization_runs', userId: userId);

    int reviewCount = localReviews.length;
    String? lastOptimizedAt = localRuns.isNotEmpty
        ? localRuns.first['created_at']?.toString()
        : null;

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteReviews = await client
            .from('review_logs')
            .select('id')
            .eq('user_id', userId)
            .limit(500);
        if (remoteReviews.length > reviewCount) {
          reviewCount = remoteReviews.length;
        }
      } catch (_) {}
    }

    return FsrsOptimizationStatus(
      canOptimize: reviewCount >= minRequiredReviews,
      reviewCount: reviewCount,
      minRequired: minRequiredReviews,
      currentWeights: FsrsOptimizationStatus.defaultFsrs6Weights,
      lastOptimizedAt: lastOptimizedAt,
    );
  }

  /// Triggers `optimize-fsrs-params` Edge Function to compute personalized 21 FSRS-6 weights.
  Future<List<double>> runOptimization(String userId) async {
    if (_supabaseProvider.isAvailable) {
      try {
        final Map<String, dynamic> res = await _edgeClient.invoke(
          'optimize-fsrs-params',
          body: <String, dynamic>{
            'userId': userId,
          },
        );
        final List<dynamic>? rawWeights = res['weights'] as List<dynamic>?;
        if (rawWeights != null && rawWeights.length == 21) {
          return rawWeights
              .map((dynamic w) => (w as num).toDouble())
              .toList(growable: false);
        }
      } catch (_) {}
    }

    return FsrsOptimizationStatus.defaultFsrs6Weights;
  }
}

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exceptions.dart';
import '../remote/edge_function_client.dart';
import '../remote/supabase_client_provider.dart';
import 'app_database.dart';
import 'outbox_queue.dart';
import 'tables/sync_tables.dart';

enum SyncStatusState {
  idle,
  syncing,
  success,
  failed,
  rateLimited,
}

/// Monotonic USN (`BigInt`) delta synchronization engine for all 28 Flashi tables.
///
/// Mirrors `src/lib/local/sync.ts` from `app-flashi`:
/// 1. Flushes pending mutations in `OutboxQueue`.
/// 2. Pulls delta changes from the `sync-pull` Edge Function using `since_usn`.
/// 3. Compares `BigInt` USN values (`recordUsn <= existingUsn` is skipped) to guarantee
///    monotonic conflict resolution.
/// 4. Handles tombstones (`deleted_at != null`) and pagination up to 50 delta pages.
class SyncEngine extends ChangeNotifier {
  SyncEngine({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    EdgeFunctionClient? edgeClient,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _edgeClient = edgeClient ?? EdgeFunctionClient.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final EdgeFunctionClient _edgeClient;
  final SupabaseClientProvider _supabaseProvider;

  bool _isSyncing = false;
  SyncStatusState _statusState = SyncStatusState.idle;
  BigInt _lastUsn = BigInt.zero;
  DateTime? _lastSyncedAt;
  String? _lastSyncError;
  int? _retryAfterSeconds;

  bool get isSyncing => _isSyncing;
  SyncStatusState get statusState => _statusState;
  BigInt get lastUsn => _lastUsn;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastSyncError => _lastSyncError;
  int? get retryAfterSeconds => _retryAfterSeconds;
  OutboxQueue get outboxQueue => _outboxQueue;

  static const String _lastUsnMetaKey = 'last_usn';

  /// Loads persisted `last_usn` cursor from local storage.
  Future<BigInt> getLastUsn() async {
    final String? stored = await _database.getSyncMeta(_lastUsnMetaKey);
    if (stored == null || stored.isEmpty) {
      return BigInt.zero;
    }
    return BigInt.tryParse(stored) ?? BigInt.zero;
  }

  /// Sets persisted `last_usn` cursor manually (useful for testing or initial sync reset).
  Future<void> setLastUsn(BigInt usn) async {
    _lastUsn = usn;
    await _database.setSyncMeta(_lastUsnMetaKey, usn.toString());
    notifyListeners();
  }

  /// Applies a batch of table changes from `sync-pull` with `BigInt` USN comparison.
  ///
  /// Exposed for unit testing monotonic USN conflict resolution.
  Future<int> applyDeltaBatch(
    Map<String, List<Map<String, dynamic>>> changesByTable,
  ) async {
    int appliedCount = 0;

    for (final String tableName in SyncTables.allTables) {
      final List<Map<String, dynamic>>? records = changesByTable[tableName];
      if (records == null || records.isEmpty) {
        continue;
      }

      for (final Map<String, dynamic> record in records) {
        final String key = SyncTables.extractRowKey(tableName, record);
        if (key.isEmpty) {
          continue;
        }

        final BigInt incomingUsn =
            BigInt.tryParse(record['usn']?.toString() ?? '0') ?? BigInt.zero;

        final Map<String, dynamic>? existing =
            await _database.getRow(tableName, key);
        if (existing != null) {
          final BigInt existingUsn =
              BigInt.tryParse(existing['usn']?.toString() ?? '0') ??
                  BigInt.zero;
          if (incomingUsn > BigInt.zero &&
              existingUsn > BigInt.zero &&
              incomingUsn <= existingUsn) {
            // Skip stale or duplicate USN update
            continue;
          }
        }

        if (record['deleted_at'] != null) {
          await _database.deleteRow(tableName, key);
        } else {
          await _database.upsertRow(tableName, record, customKey: key);
        }
        appliedCount++;
      }
    }

    return appliedCount;
  }

  /// Runs a full push (outbox) + pull (`sync-pull`) cycle.
  Future<void> syncNow() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    _statusState = SyncStatusState.syncing;
    _lastSyncError = null;
    _retryAfterSeconds = null;
    notifyListeners();

    try {
      // 1. Flush pending outbox mutations first
      await _outboxQueue.processOutbox(_executeOutboxMutation);

      // 2. Pull delta changes since last USN if Supabase is configured
      if (!_supabaseProvider.isAvailable) {
        _lastUsn = await getLastUsn();
        _lastSyncedAt = DateTime.now();
        _statusState = SyncStatusState.success;
        return;
      }

      BigInt currentUsn = await getLastUsn();
      bool hasMore = true;
      int safetyPages = 0;
      const int maxSafetyPages = 50;

      while (hasMore && safetyPages < maxSafetyPages) {
        safetyPages++;
        final Map<String, dynamic> response = await _edgeClient.invoke(
          'sync-pull',
          body: <String, dynamic>{
            'since_usn': currentUsn.toString(),
            'tables': SyncTables.allTables,
          },
        );

        final Map<String, dynamic> rawChanges =
            (response['changes'] as Map<String, dynamic>?) ??
                <String, dynamic>{};
        final Map<String, List<Map<String, dynamic>>> typedChanges =
            <String, List<Map<String, dynamic>>>{};

        for (final MapEntry<String, dynamic> entry in rawChanges.entries) {
          if (entry.value is List) {
            typedChanges[entry.key] = (entry.value as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
          }
        }

        await applyDeltaBatch(typedChanges);

        final BigInt nextUsn = BigInt.tryParse(
              response['max_usn']?.toString() ??
                  response['last_usn']?.toString() ??
                  currentUsn.toString(),
            ) ??
            currentUsn;

        if (nextUsn > currentUsn) {
          currentUsn = nextUsn;
          await _database.setSyncMeta(_lastUsnMetaKey, currentUsn.toString());
        }

        hasMore = response['has_more'] == true;
      }

      _lastUsn = currentUsn;
      _lastSyncedAt = DateTime.now();
      _statusState = SyncStatusState.success;
    } on RateLimitException catch (e) {
      _statusState = SyncStatusState.rateLimited;
      _retryAfterSeconds = e.retryAfterSeconds;
      _lastSyncError = e.message;
    } catch (error) {
      _statusState = SyncStatusState.failed;
      _lastSyncError = error.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _executeOutboxMutation(
    String tableName,
    String action,
    Map<String, dynamic> payload,
  ) async {
    if (!_supabaseProvider.isAvailable) {
      throw StateError('Supabase client is offline or unavailable.');
    }

    final client = _supabaseProvider.client!;
    if (tableName == 'review_logs' && action == 'insert') {
      await client.rpc(
        'submit_review',
        params: <String, dynamic>{
          'p_card_id': payload['card_id'],
          'p_rating': payload['rating'],
          'p_duration_ms': payload['review_duration_ms'] ?? payload['duration_ms'] ?? 0,
          'p_idempotency_key': payload['idempotency_key'],
          'p_reviewed_at': payload['reviewed_at'] ?? payload['review_time'],
        },
      );
      return;
    }

    if (tableName == 'rpc' && action == 'insert') {
      final String fn = payload['fn']?.toString() ?? '';
      final Map<String, dynamic> params =
          (payload['params'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      if (fn.isNotEmpty) {
        await client.rpc(fn, params: params);
      }
      return;
    }

    if (action == 'insert' || action == 'update') {
      await client.from(tableName).upsert(payload);
    } else if (action == 'delete') {
      final String? id = payload['id']?.toString();
      if (id != null && id.isNotEmpty) {
        await client.from(tableName).delete().eq('id', id);
      }
    }
  }
}

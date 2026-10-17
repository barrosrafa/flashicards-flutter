import 'package:flutter/foundation.dart';

import 'app_database.dart';

/// Offline mutation outbox with idempotency coalescing and session XP dependency deferral.
///
/// Mirrors `src/lib/local/outbox.ts` from `app-flashi`:
/// - Coalesces duplicate `review_logs` (by `idempotency_key`) and `rpc` calls (`sync_session_xp_confirmed` by `p_session_id`).
/// - Defers `sync_session_xp_confirmed` while any `review_logs` mutation for the same `session_id` is still pending in the outbox.
class OutboxQueue extends ChangeNotifier {
  OutboxQueue({
    FlashiLocalDatabase? database,
  }) : _database = database ?? FlashiLocalDatabase.instance;

  final FlashiLocalDatabase _database;
  bool _isProcessing = false;
  int _pendingCount = 0;
  String? _lastError;

  bool get isProcessing => _isProcessing;
  int get pendingCount => _pendingCount;
  String? get lastError => _lastError;

  static const int maxRetries = 5;

  /// Enqueues an offline mutation with idempotency deduplication.
  Future<int> enqueueMutation({
    required String tableName,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final List<Map<String, dynamic>> existingOps =
        await _database.getOutboxOperations();
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Deduplicate review_logs by idempotency_key
    if (tableName == 'review_logs' && action == 'insert') {
      final String? idempotencyKey = payload['idempotency_key']?.toString();
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        for (final Map<String, dynamic> op in existingOps) {
          final Map<String, dynamic> opPayload =
              (op['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          if (op['table_name'] == 'review_logs' &&
              opPayload['idempotency_key']?.toString() == idempotencyKey) {
            final int id = op['id'] as int;
            await _database.updateOutboxOperation(id, payload: payload);
            await refreshCount();
            return id;
          }
        }
      }
    }

    // 2. Deduplicate sync_session_xp_confirmed by p_session_id
    if (tableName == 'rpc' &&
        action == 'insert' &&
        payload['fn'] == 'sync_session_xp_confirmed') {
      final Map<String, dynamic> params =
          (payload['params'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final String? sessionId = params['p_session_id']?.toString();
      if (sessionId != null && sessionId.isNotEmpty) {
        for (final Map<String, dynamic> op in existingOps) {
          final Map<String, dynamic> opPayload =
              (op['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final Map<String, dynamic> opParams =
              (opPayload['params'] as Map<String, dynamic>?) ??
                  <String, dynamic>{};
          if (op['table_name'] == 'rpc' &&
              opPayload['fn'] == 'sync_session_xp_confirmed' &&
              opParams['p_session_id']?.toString() == sessionId) {
            final int id = op['id'] as int;
            await _database.updateOutboxOperation(id, payload: payload);
            await refreshCount();
            return id;
          }
        }
      }
    }

    final int insertedId = await _database.insertOutboxOperation(
      tableName: tableName,
      action: action,
      payload: payload,
      timestamp: nowMs,
    );
    await refreshCount();
    return insertedId;
  }

  /// Processes all pending outbox items in FIFO order using [executor].
  ///
  /// Defers `sync_session_xp_confirmed` if any `review_logs` item for the same
  /// `session_id` is still pending or failed earlier in the pass.
  Future<void> processOutbox(
    Future<void> Function(
      String tableName,
      String action,
      Map<String, dynamic> payload,
    ) executor,
  ) async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> ops =
          await _database.getOutboxOperations();
      final Set<String> pendingReviewSessionIds = <String>{};

      // Pre-scan pending review_logs session IDs
      for (final Map<String, dynamic> op in ops) {
        if (op['table_name'] == 'review_logs') {
          final Map<String, dynamic> p =
              (op['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final String? sid = p['session_id']?.toString();
          if (sid != null && sid.isNotEmpty) {
            pendingReviewSessionIds.add(sid);
          }
        }
      }

      for (final Map<String, dynamic> op in ops) {
        final int id = op['id'] as int;
        final String tableName = op['table_name']?.toString() ?? '';
        final String action = op['action']?.toString() ?? '';
        final Map<String, dynamic> payload =
            (op['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final int retryCount = (op['retry_count'] as num?)?.toInt() ?? 0;

        if (retryCount >= maxRetries) {
          continue;
        }

        // Defer sync_session_xp_confirmed if review_logs for that session are still pending
        if (tableName == 'rpc' &&
            payload['fn'] == 'sync_session_xp_confirmed') {
          final Map<String, dynamic> params =
              (payload['params'] as Map<String, dynamic>?) ??
                  <String, dynamic>{};
          final String? sessionId = params['p_session_id']?.toString();
          if (sessionId != null &&
              pendingReviewSessionIds.contains(sessionId)) {
            continue;
          }
        }

        try {
          await executor(tableName, action, payload);
          await _database.deleteOutboxOperation(id);
          if (tableName == 'review_logs') {
            final String? sid = payload['session_id']?.toString();
            if (sid != null) {
              // Check if any other review_logs remain for this session
              final List<Map<String, dynamic>> remaining =
                  await _database.getOutboxOperations();
              final bool stillHasSessionReviews = remaining.any(
                (Map<String, dynamic> r) =>
                    r['table_name'] == 'review_logs' &&
                    (r['payload'] as Map<String, dynamic>?)?['session_id']
                            ?.toString() ==
                        sid,
              );
              if (!stillHasSessionReviews) {
                pendingReviewSessionIds.remove(sid);
              }
            }
          }
        } catch (error) {
          _lastError = error.toString();
          await _database.updateOutboxOperation(
            id,
            retryCount: retryCount + 1,
            lastError: error.toString(),
          );
        }
      }
    } finally {
      _isProcessing = false;
      await refreshCount();
    }
  }

  Future<void> refreshCount() async {
    final List<Map<String, dynamic>> ops =
        await _database.getOutboxOperations();
    _pendingCount = ops.length;
    notifyListeners();
  }
}

import 'package:flashi_mobile/data/local/app_database.dart';
import 'package:flashi_mobile/data/local/outbox_queue.dart';
import 'package:flashi_mobile/data/local/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncEngine & OutboxQueue', () {
    test('skips stale USN records and applies newer BigInt USN records', () async {
      final FlashiLocalDatabase db = FlashiLocalDatabase.inMemory();
      final SyncEngine syncEngine = SyncEngine(
        database: db,
        outboxQueue: OutboxQueue(database: db),
      );

      await syncEngine.applyDeltaBatch(<String, List<Map<String, dynamic>>>{
        'decks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'deck-1',
            'title': 'Versao USN 100',
            'usn': '100',
          },
        ],
      });

      // Attempt to overwrite with older USN 95 -> should be ignored
      await syncEngine.applyDeltaBatch(<String, List<Map<String, dynamic>>>{
        'decks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'deck-1',
            'title': 'Versao Antiga USN 95',
            'usn': '95',
          },
        ],
      });

      final Map<String, dynamic>? storedAfterStale =
          await db.getRow('decks', 'deck-1');
      expect(storedAfterStale?['title'], 'Versao USN 100');

      // Apply newer USN 105 -> should update
      await syncEngine.applyDeltaBatch(<String, List<Map<String, dynamic>>>{
        'decks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'deck-1',
            'title': 'Versao Nova USN 105',
            'usn': '105',
          },
        ],
      });

      final Map<String, dynamic>? storedAfterNew =
          await db.getRow('decks', 'deck-1');
      expect(storedAfterNew?['title'], 'Versao Nova USN 105');
    });

    test(
      'coalesces duplicate review_logs by idempotency_key and defers sync_session_xp_confirmed if review fails',
      () async {
        final FlashiLocalDatabase db = FlashiLocalDatabase.inMemory();
        final OutboxQueue outbox = OutboxQueue(database: db);

        final int id1 = await outbox.enqueueMutation(
          tableName: 'review_logs',
          action: 'insert',
          payload: <String, dynamic>{
            'card_id': 'c1',
            'rating': 3,
            'session_id': 'sess-1',
            'idempotency_key': 'idem-1',
          },
        );

        final int id2 = await outbox.enqueueMutation(
          tableName: 'review_logs',
          action: 'insert',
          payload: <String, dynamic>{
            'card_id': 'c1',
            'rating': 4,
            'session_id': 'sess-1',
            'idempotency_key': 'idem-1',
          },
        );

        expect(id1, equals(id2));
        expect(outbox.pendingCount, 1);

        await outbox.enqueueMutation(
          tableName: 'rpc',
          action: 'insert',
          payload: <String, dynamic>{
            'fn': 'sync_session_xp_confirmed',
            'params': <String, dynamic>{
              'p_session_id': 'sess-1',
            },
          },
        );

        expect(outbox.pendingCount, 2);

        final List<String> executedCalls = <String>[];
        await outbox.processOutbox((
          String tableName,
          String action,
          Map<String, dynamic> payload,
        ) async {
          if (tableName == 'review_logs') {
            throw Exception('Simulated offline error');
          }
          executedCalls.add(tableName);
        });

        // Because review_logs for sess-1 failed, sync_session_xp_confirmed must be deferred!
        expect(executedCalls, isEmpty);
        expect(outbox.pendingCount, 2);
      },
    );
  });
}

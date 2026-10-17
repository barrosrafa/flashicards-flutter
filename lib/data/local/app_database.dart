import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'tables/sync_tables.dart';

/// Local offline-first database for Flashi.
///
/// Mirrors `FlashiDB` (`src/lib/local/db.ts`) from `app-flashi` with SQLite persistence
/// on Android/iOS and an optional in-memory mode for fast deterministic unit tests.
class FlashiLocalDatabase {
  FlashiLocalDatabase._({
    required bool inMemory,
  }) : _inMemory = inMemory;

  factory FlashiLocalDatabase.inMemory() {
    return FlashiLocalDatabase._(inMemory: true);
  }

  static FlashiLocalDatabase? _shared;

  static FlashiLocalDatabase get instance {
    return _shared ??= FlashiLocalDatabase._(inMemory: false);
  }

  final bool _inMemory;
  Database? _db;

  /// Fallback in-memory tables when running in unit tests or before SQLite initializes.
  final Map<String, Map<String, Map<String, dynamic>>> _memoryStore =
      <String, Map<String, Map<String, dynamic>>>{};
  final List<Map<String, dynamic>> _memoryOutbox = <Map<String, dynamic>>[];
  int _nextOutboxId = 1;

  Future<Database?> _getDatabase() async {
    if (_inMemory) {
      return null;
    }
    if (_db != null) {
      return _db;
    }
    try {
      final String databasesPath = await getDatabasesPath();
      final String dbPath = p.join(databasesPath, 'flashi_local_v4.db');
      _db = await openDatabase(
        dbPath,
        version: 4,
        onCreate: (Database db, int version) async {
          await _createTables(db);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          await _createTables(db);
        },
      );
      return _db;
    } catch (_) {
      // Fallback to in-memory store if native sqflite channel is unavailable.
      return null;
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_records (
        table_name TEXT NOT NULL,
        row_key TEXT NOT NULL,
        user_id TEXT,
        deck_id TEXT,
        usn INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        updated_at TEXT,
        payload_json TEXT NOT NULL,
        PRIMARY KEY (table_name, row_key)
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_records_table_user
      ON sync_records (table_name, user_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_records_table_deck
      ON sync_records (table_name, deck_id)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS outbox_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        action TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_meta (
        key TEXT PRIMARY KEY,
        value_json TEXT NOT NULL
      )
    ''');
  }

  /// Upserts a row into one of the 28 synchronized tables (or local auxiliary stores).
  Future<void> upsertRow(
    String tableName,
    Map<String, dynamic> row, {
    String? customKey,
  }) async {
    final String rowKey =
        customKey ?? SyncTables.extractRowKey(tableName, row);
    if (rowKey.isEmpty) {
      return;
    }

    final Map<String, dynamic> normalized = Map<String, dynamic>.from(row);
    final int usn = int.tryParse(normalized['usn']?.toString() ?? '0') ?? 0;
    final String? userId = normalized['user_id']?.toString();
    final String? deckId = normalized['deck_id']?.toString();
    final String? deletedAt = normalized['deleted_at']?.toString();
    final String? updatedAt = normalized['updated_at']?.toString();

    final Database? db = await _getDatabase();
    if (db == null) {
      final Map<String, Map<String, dynamic>> tableMap =
          _memoryStore.putIfAbsent(
        tableName,
        () => <String, Map<String, dynamic>>{},
      );
      tableMap[rowKey] = normalized;
      return;
    }

    await db.insert(
      'sync_records',
      <String, Object?>{
        'table_name': tableName,
        'row_key': rowKey,
        'user_id': userId,
        'deck_id': deckId,
        'usn': usn,
        'deleted_at': deletedAt,
        'updated_at': updatedAt,
        'payload_json': jsonEncode(normalized),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Soft-deletes or hard-deletes a row from [tableName].
  Future<void> deleteRow(String tableName, String rowKey) async {
    final Database? db = await _getDatabase();
    if (db == null) {
      _memoryStore[tableName]?.remove(rowKey);
      return;
    }
    await db.delete(
      'sync_records',
      where: 'table_name = ? AND row_key = ?',
      whereArgs: <Object?>[tableName, rowKey],
    );
  }

  /// Gets a single row by key from [tableName].
  Future<Map<String, dynamic>?> getRow(String tableName, String rowKey) async {
    final Database? db = await _getDatabase();
    if (db == null) {
      final Map<String, dynamic>? row = _memoryStore[tableName]?[rowKey];
      return row == null ? null : Map<String, dynamic>.from(row);
    }

    final List<Map<String, Object?>> rows = await db.query(
      'sync_records',
      columns: <String>['payload_json'],
      where: 'table_name = ? AND row_key = ?',
      whereArgs: <Object?>[tableName, rowKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final String rawJson = rows.first['payload_json']?.toString() ?? '{}';
    return jsonDecode(rawJson) as Map<String, dynamic>;
  }

  /// Queries all non-deleted rows in [tableName], optionally filtered by [userId] or [deckId].
  Future<List<Map<String, dynamic>>> queryTable(
    String tableName, {
    String? userId,
    String? deckId,
    bool includeDeleted = false,
  }) async {
    final Database? db = await _getDatabase();
    if (db == null) {
      final Iterable<Map<String, dynamic>> values =
          _memoryStore[tableName]?.values ?? const <Map<String, dynamic>>[];
      return values.where((Map<String, dynamic> row) {
        if (!includeDeleted && row['deleted_at'] != null) {
          return false;
        }
        if (userId != null && row['user_id']?.toString() != userId) {
          return false;
        }
        if (deckId != null && row['deck_id']?.toString() != deckId) {
          return false;
        }
        return true;
      }).map((Map<String, dynamic> r) => Map<String, dynamic>.from(r)).toList();
    }

    final List<String> clauses = <String>['table_name = ?'];
    final List<Object?> args = <Object?>[tableName];
    if (!includeDeleted) {
      clauses.add('deleted_at IS NULL');
    }
    if (userId != null) {
      clauses.add('user_id = ?');
      args.add(userId);
    }
    if (deckId != null) {
      clauses.add('deck_id = ?');
      args.add(deckId);
    }

    final List<Map<String, Object?>> rows = await db.query(
      'sync_records',
      columns: <String>['payload_json'],
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );

    return rows
        .map(
          (Map<String, Object?> r) =>
              jsonDecode(r['payload_json']?.toString() ?? '{}')
                  as Map<String, dynamic>,
        )
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Outbox Queue Persistence
  // ---------------------------------------------------------------------------

  Future<int> insertOutboxOperation({
    required String tableName,
    required String action,
    required Map<String, dynamic> payload,
    required int timestamp,
  }) async {
    final Database? db = await _getDatabase();
    if (db == null) {
      final int id = _nextOutboxId++;
      _memoryOutbox.add(<String, dynamic>{
        'id': id,
        'table_name': tableName,
        'action': action,
        'payload': Map<String, dynamic>.from(payload),
        'timestamp': timestamp,
        'retry_count': 0,
        'last_error': null,
      });
      return id;
    }

    return db.insert('outbox_queue', <String, Object?>{
      'table_name': tableName,
      'action': action,
      'payload_json': jsonEncode(payload),
      'timestamp': timestamp,
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getOutboxOperations() async {
    final Database? db = await _getDatabase();
    if (db == null) {
      final List<Map<String, dynamic>> sorted =
          List<Map<String, dynamic>>.from(_memoryOutbox)
            ..sort(
              (Map<String, dynamic> a, Map<String, dynamic> b) =>
                  (a['timestamp'] as int).compareTo(b['timestamp'] as int),
            );
      return sorted;
    }

    final List<Map<String, Object?>> rows = await db.query(
      'outbox_queue',
      orderBy: 'timestamp ASC, id ASC',
    );

    return rows.map((Map<String, Object?> row) {
      final String rawPayload = row['payload_json']?.toString() ?? '{}';
      return <String, dynamic>{
        'id': (row['id'] as num?)?.toInt() ?? 0,
        'table_name': row['table_name']?.toString() ?? '',
        'action': row['action']?.toString() ?? '',
        'payload': jsonDecode(rawPayload) as Map<String, dynamic>,
        'timestamp': (row['timestamp'] as num?)?.toInt() ?? 0,
        'retry_count': (row['retry_count'] as num?)?.toInt() ?? 0,
        'last_error': row['last_error']?.toString(),
      };
    }).toList(growable: false);
  }

  Future<void> updateOutboxOperation(
    int id, {
    Map<String, dynamic>? payload,
    int? retryCount,
    String? lastError,
  }) async {
    final Database? db = await _getDatabase();
    if (db == null) {
      for (final Map<String, dynamic> item in _memoryOutbox) {
        if (item['id'] == id) {
          if (payload != null) {
            item['payload'] = Map<String, dynamic>.from(payload);
          }
          if (retryCount != null) {
            item['retry_count'] = retryCount;
          }
          if (lastError != null) {
            item['last_error'] = lastError;
          }
          break;
        }
      }
      return;
    }

    final Map<String, Object?> values = <String, Object?>{};
    if (payload != null) {
      values['payload_json'] = jsonEncode(payload);
    }
    if (retryCount != null) {
      values['retry_count'] = retryCount;
    }
    if (lastError != null) {
      values['last_error'] = lastError;
    }
    if (values.isNotEmpty) {
      await db.update(
        'outbox_queue',
        values,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    }
  }

  Future<void> deleteOutboxOperation(int id) async {
    final Database? db = await _getDatabase();
    if (db == null) {
      _memoryOutbox.removeWhere((Map<String, dynamic> item) => item['id'] == id);
      return;
    }
    await db.delete(
      'outbox_queue',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  // ---------------------------------------------------------------------------
  // Sync Meta (last_usn, scoped user_id, etc.)
  // ---------------------------------------------------------------------------

  Future<String?> getSyncMeta(String key) async {
    final Database? db = await _getDatabase();
    if (db == null) {
      return _memoryStore['__sync_meta__']?[key]?['value']?.toString();
    }
    final List<Map<String, Object?>> rows = await db.query(
      'sync_meta',
      columns: <String>['value_json'],
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value_json']?.toString();
  }

  Future<void> setSyncMeta(String key, String value) async {
    final Database? db = await _getDatabase();
    if (db == null) {
      final Map<String, Map<String, dynamic>> meta = _memoryStore.putIfAbsent(
        '__sync_meta__',
        () => <String, Map<String, dynamic>>{},
      );
      meta[key] = <String, dynamic>{'value': value};
      return;
    }
    await db.insert(
      'sync_meta',
      <String, Object?>{
        'key': key,
        'value_json': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Purges all local user data on account switch or sign-out.
  Future<void> clearAllUserData() async {
    _memoryStore.clear();
    _memoryOutbox.clear();
    final Database? db = await _getDatabase();
    if (db != null) {
      await db.delete('sync_records');
      await db.delete('outbox_queue');
      await db.delete('sync_meta');
    }
  }
}

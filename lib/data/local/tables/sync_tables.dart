/// Canonical list of the 28 synchronized tables in Flashi and their key schemas.
///
/// Mirrors `SYNC_TABLES` and `COMPOSITE_KEY_MAP` in `src/lib/local/sync.ts` from `app-flashi`.
class SyncTables {
  const SyncTables._();

  static const List<String> allTables = <String>[
    'decks',
    'notes',
    'note_card_definitions',
    'note_cloze_deletions',
    'note_references',
    'note_image_occlusion_boxes',
    'cards',
    'card_tags',
    'card_media',
    'card_learning_state',
    'card_templates',
    'field_definitions',
    'tags',
    'review_logs',
    'study_settings',
    'user_deck_settings',
    'daily_statistics',
    'fsrs_optimization_runs',
    'deck_collaborators',
    'deck_exams',
    'user_gamification_profiles',
    'user_badges',
    'badges_definition',
    'socratic_remediation_sessions',
    'ai_ingestion_jobs',
    'anki_transfer_jobs',
    'profiles',
    'mcp_tool_audit',
  ];

  /// Composite primary key columns for tables without a single `id` column.
  static const Map<String, List<String>> compositeKeyColumns =
      <String, List<String>>{
    'card_tags': <String>['card_id', 'tag_id'],
    'card_learning_state': <String>['user_id', 'card_id'],
    'study_settings': <String>['user_id'],
    'user_deck_settings': <String>['user_id', 'deck_id'],
    'daily_statistics': <String>['user_id', 'date'],
    'user_gamification_profiles': <String>['user_id'],
  };

  /// Computes a deterministic primary key string for any row in [tableName].
  static String extractRowKey(String tableName, Map<String, dynamic> row) {
    final List<String>? compositeCols = compositeKeyColumns[tableName];
    if (compositeCols != null && compositeCols.isNotEmpty) {
      return compositeCols
          .map((String col) => row[col]?.toString() ?? '')
          .join(':');
    }
    return row['id']?.toString() ?? '';
  }
}

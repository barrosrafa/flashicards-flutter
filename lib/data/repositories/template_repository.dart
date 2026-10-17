import '../../core/utils/crypto_utils.dart';
import '../../domain/models/card_template.dart';
import '../local/app_database.dart';
import '../local/outbox_queue.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for customizable Note/Card Templates (`card_templates` & `field_definitions`).
///
/// Mirrors `src/lib/services/template-service.ts` from `app-flashi`.
class TemplateRepository {
  TemplateRepository({
    FlashiLocalDatabase? database,
    OutboxQueue? outboxQueue,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _outboxQueue = outboxQueue ?? OutboxQueue(),
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final OutboxQueue _outboxQueue;
  final SupabaseClientProvider _supabaseProvider;

  Future<List<CardTemplate>> listTemplates({required String userId}) async {
    final List<Map<String, dynamic>> localRows =
        await _database.queryTable('card_templates', userId: userId);
    if (localRows.isNotEmpty) {
      return localRows.map(CardTemplate.fromJson).toList(growable: false);
    }

    final client = _supabaseProvider.client;
    if (client != null) {
      try {
        final List<dynamic> remoteRows = await client
            .from('card_templates')
            .select('*, fields:field_definitions(*)')
            .or('user_id.eq.$userId,is_system.eq.true')
            .isFilter('deleted_at', null);
        if (remoteRows.isNotEmpty) {
          return remoteRows
              .whereType<Map<String, dynamic>>()
              .map(CardTemplate.fromJson)
              .toList(growable: false);
        }
      } catch (_) {}
    }

    final String nowIso = DateTime.now().toUtc().toIso8601String();
    return <CardTemplate>[
      CardTemplate(
        id: 'system-basic',
        userId: userId,
        name: 'Basico (Frente e Verso)',
        description: 'Modelo padrao com pergunta na frente e resposta no verso.',
        isCloze: false,
        isSystem: true,
        fields: const <TemplateField>[
          TemplateField(
            id: 'f-front',
            templateId: 'system-basic',
            name: 'Front',
            fieldType: 'text',
            isRequired: true,
            position: 0,
          ),
          TemplateField(
            id: 'f-back',
            templateId: 'system-basic',
            name: 'Back',
            fieldType: 'text',
            isRequired: true,
            position: 1,
          ),
        ],
        generationRules: const <CardGenerationRule>[
          CardGenerationRule(
            name: 'Card 1',
            frontTemplate: '{{Front}}',
            backTemplate: '{{FrontSide}}\n\n---\n\n{{Back}}',
          ),
        ],
        createdAt: nowIso,
      ),
      CardTemplate(
        id: 'system-cloze',
        userId: userId,
        name: 'Omissao de Palavras (Cloze)',
        description: 'Gera um cartao para cada lacuna {{c1::...}} no texto.',
        isCloze: true,
        isSystem: true,
        fields: const <TemplateField>[
          TemplateField(
            id: 'f-text',
            templateId: 'system-cloze',
            name: 'Text',
            fieldType: 'text',
            isRequired: true,
            position: 0,
          ),
          TemplateField(
            id: 'f-extra',
            templateId: 'system-cloze',
            name: 'Extra',
            fieldType: 'text',
            isRequired: false,
            position: 1,
          ),
        ],
        generationRules: const <CardGenerationRule>[
          CardGenerationRule(
            name: 'Cloze',
            frontTemplate: '{{cloze:Text}}',
            backTemplate: '{{cloze:Text}}\n\n{{#Extra}}---\n{{Extra}}{{/Extra}}',
          ),
        ],
        createdAt: nowIso,
      ),
    ];
  }

  Future<CardTemplate> createTemplate({
    required String userId,
    required String name,
    String? description,
    required bool isCloze,
    required List<String> fieldNames,
    required String frontTemplate,
    required String backTemplate,
  }) async {
    final String templateId = CryptoUtils.generateUuidV4();
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final List<TemplateField> fields = fieldNames
        .asMap()
        .entries
        .map(
          (MapEntry<int, String> e) => TemplateField(
            id: CryptoUtils.generateUuidV4(),
            templateId: templateId,
            name: e.value.trim(),
            fieldType: 'text',
            isRequired: e.key == 0,
            position: e.key,
          ),
        )
        .toList(growable: false);

    final List<CardGenerationRule> rules = <CardGenerationRule>[
      CardGenerationRule(
        name: isCloze ? 'Cloze' : 'Card 1',
        frontTemplate: frontTemplate,
        backTemplate: backTemplate,
      ),
    ];

    final Map<String, dynamic> payload = <String, dynamic>{
      'id': templateId,
      'user_id': userId,
      'name': name.trim(),
      'description': description?.trim(),
      'is_cloze': isCloze,
      'is_system': false,
      'fields': fields.map((TemplateField f) => f.toJson()).toList(),
      'generation_rules':
          rules.map((CardGenerationRule r) => r.toJson()).toList(),
      'created_at': nowIso,
    };

    await _database.upsertRow('card_templates', payload);
    await _outboxQueue.enqueueMutation(
      tableName: 'card_templates',
      action: 'insert',
      payload: payload,
    );

    return CardTemplate.fromJson(payload);
  }
}

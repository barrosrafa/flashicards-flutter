import 'dart:convert';

/// Modelos de domínio para Notas, Cloze Deletions e Referências entre Notas.
class Note {
  const Note({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.fields,
    this.modelKind = 'basic',
    this.templateId,
    this.source = 'native',
    this.sourceFormat = 'native',
    this.sourceMetadata = const <String, dynamic>{},
    this.checksum,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.usn = 0,
  });

  final String id;
  final String deckId;
  final String userId;
  final Map<String, dynamic> fields;
  final String modelKind;
  final String? templateId;
  final String? source;
  final String? sourceFormat;
  final Map<String, dynamic> sourceMetadata;
  final String? checksum;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int usn;

  Map<String, String> get fieldValues => fields.map(
        (String k, dynamic v) =>
            MapEntry<String, String>(k, (v ?? '').toString()),
      );

  String get frontPreview =>
      (fields['front'] ??
              fields['Front'] ??
              fields['text'] ??
              fields['Text'] ??
              fields.values.firstOrNull ??
              '')
          .toString();

  String get backPreview =>
      (fields['back'] ?? fields['Back'] ?? fields['extra'] ?? fields['Extra'] ?? '')
          .toString();

  factory Note.fromJson(Map<String, dynamic> json) {
    final dynamic rawFields = json['fields'] ?? json['field_values'];
    Map<String, dynamic> parsedFields = const <String, dynamic>{};
    if (rawFields is Map<String, dynamic>) {
      parsedFields = Map<String, dynamic>.from(rawFields);
    } else if (rawFields is Map) {
      parsedFields = rawFields.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v),
      );
    } else if (rawFields is String && rawFields.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rawFields);
        if (decoded is Map<String, dynamic>) parsedFields = decoded;
      } catch (_) {}
    }

    final dynamic rawMeta = json['source_metadata'];
    final Map<String, dynamic> parsedMeta = rawMeta is Map<String, dynamic>
        ? rawMeta
        : const <String, dynamic>{};

    return Note(
      id: (json['id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      fields: parsedFields,
      modelKind: (json['model_kind'] ?? 'basic').toString(),
      templateId: json['template_id']?.toString(),
      source: (json['source'] ?? json['source_type'] ?? 'native').toString(),
      sourceFormat: (json['source_format'] ?? 'native').toString(),
      sourceMetadata: parsedMeta,
      checksum: json['checksum']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'deck_id': deckId,
      'user_id': userId,
      'fields': fields,
      'field_values': fields,
      'model_kind': modelKind,
      'template_id': templateId,
      'source': source,
      'source_type': source,
      'source_format': sourceFormat,
      'source_metadata': sourceMetadata,
      'checksum': checksum,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'usn': usn,
    };
  }
}

class NoteInput {
  NoteInput({
    required this.deckId,
    Map<String, dynamic>? fields,
    Map<String, String>? fieldValues,
    this.modelKind = 'basic',
    this.templateId,
    String? source,
    String? sourceType,
    this.sourceFormat = 'native',
    this.sourceMetadata = const <String, dynamic>{},
  })  : fields = fields ??
            (fieldValues != null
                ? Map<String, dynamic>.from(fieldValues)
                : const <String, dynamic>{}),
        source = source ?? sourceType ?? 'native';

  final String deckId;
  final Map<String, dynamic> fields;
  final String modelKind;
  final String? templateId;
  final String source;
  final String sourceFormat;
  final Map<String, dynamic> sourceMetadata;

  String? get sourceType => source;

  Map<String, String> get fieldValues => fields.map(
        (String k, dynamic v) =>
            MapEntry<String, String>(k, (v ?? '').toString()),
      );
}

class NoteClozeDeletion {
  const NoteClozeDeletion({
    this.id = '',
    this.noteId = '',
    this.fieldName = 'Text',
    int? clozeOrdinal,
    int? clozeIndex,
    this.targetText = '',
    String? hint,
    String? hintText,
    this.startOffset,
    this.endOffset,
  })  : clozeOrdinal = clozeOrdinal ?? clozeIndex ?? 1,
        hint = hint ?? hintText;

  final String id;
  final String noteId;
  final String fieldName;
  final int clozeOrdinal;
  int get clozeIndex => clozeOrdinal;
  final String targetText;
  final String? hint;
  String? get hintText => hint;
  final int? startOffset;
  final int? endOffset;

  factory NoteClozeDeletion.fromJson(Map<String, dynamic> json) {
    return NoteClozeDeletion(
      id: (json['id'] ?? '').toString(),
      noteId: (json['note_id'] ?? '').toString(),
      fieldName: (json['field_name'] ?? 'Text').toString(),
      clozeOrdinal: (json['cloze_ordinal'] ?? json['cloze_index'] as num?)?.toInt() ?? 1,
      targetText: (json['target_text'] ?? '').toString(),
      hint: (json['hint'] ?? json['hint_text'])?.toString(),
      startOffset: (json['start_offset'] as num?)?.toInt(),
      endOffset: (json['end_offset'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'note_id': noteId,
        'field_name': fieldName,
        'cloze_ordinal': clozeOrdinal,
        'target_text': targetText,
        if (hint != null) 'hint': hint,
        if (startOffset != null) 'start_offset': startOffset,
        if (endOffset != null) 'end_offset': endOffset,
      };
}

class NoteReference {
  const NoteReference({
    required this.id,
    required this.sourceNoteId,
    required this.targetNoteId,
    this.createdAt,
  });

  final String id;
  final String sourceNoteId;
  final String targetNoteId;
  final String? createdAt;

  factory NoteReference.fromJson(Map<String, dynamic> json) {
    return NoteReference(
      id: (json['id'] ?? '').toString(),
      sourceNoteId: (json['source_note_id'] ?? '').toString(),
      targetNoteId: (json['target_note_id'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'source_note_id': sourceNoteId,
        'target_note_id': targetNoteId,
        'created_at': createdAt,
      };
}

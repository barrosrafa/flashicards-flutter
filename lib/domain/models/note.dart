import 'dart:convert';

/// Modelos de domínio para Notas, Cloze Deletions e Referências entre Notas.
class Note {
  const Note({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.fields,
    this.templateId,
    this.source = 'native',
    this.sourceFormat = 'native',
    this.updatedAt,
    this.deletedAt,
    this.usn = 0,
  });

  final String id;
  final String deckId;
  final String userId;
  final Map<String, dynamic> fields;
  final String? templateId;
  final String? source;
  final String? sourceFormat;
  final String? updatedAt;
  final String? deletedAt;
  final int usn;

  String get frontPreview =>
      (fields['front'] ?? fields['Front'] ?? fields.values.firstOrNull ?? '')
          .toString();

  String get backPreview =>
      (fields['back'] ?? fields['Back'] ?? '').toString();

  factory Note.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    Map<String, dynamic> parsedFields = const {};
    if (rawFields is Map<String, dynamic>) {
      parsedFields = rawFields;
    } else if (rawFields is String && rawFields.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFields);
        if (decoded is Map<String, dynamic>) parsedFields = decoded;
      } catch (_) {}
    }

    return Note(
      id: (json['id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      fields: parsedFields,
      templateId: json['template_id']?.toString(),
      source: json['source']?.toString(),
      sourceFormat: json['source_format']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deck_id': deckId,
      'user_id': userId,
      'fields': fields,
      'template_id': templateId,
      'source': source,
      'source_format': sourceFormat,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'usn': usn,
    };
  }
}

class NoteInput {
  const NoteInput({
    required this.deckId,
    required this.fields,
    this.templateId,
    this.source = 'native',
    this.sourceFormat = 'native',
  });

  final String deckId;
  final Map<String, dynamic> fields;
  final String? templateId;
  final String? source;
  final String? sourceFormat;
}

class NoteClozeDeletion {
  const NoteClozeDeletion({
    required this.id,
    required this.noteId,
    required this.fieldName,
    required this.clozeOrdinal,
    this.hint,
    this.startOffset,
    this.endOffset,
  });

  final String id;
  final String noteId;
  final String fieldName;
  final int clozeOrdinal;
  final String? hint;
  final int? startOffset;
  final int? endOffset;

  factory NoteClozeDeletion.fromJson(Map<String, dynamic> json) {
    return NoteClozeDeletion(
      id: (json['id'] ?? '').toString(),
      noteId: (json['note_id'] ?? '').toString(),
      fieldName: (json['field_name'] ?? '').toString(),
      clozeOrdinal: (json['cloze_ordinal'] as num?)?.toInt() ?? 1,
      hint: json['hint']?.toString(),
      startOffset: (json['start_offset'] as num?)?.toInt(),
      endOffset: (json['end_offset'] as num?)?.toInt(),
    );
  }
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
}

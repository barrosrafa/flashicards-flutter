import 'dart:convert';

/// Modelos de domínio para Cartões, Tags e Mídias de Cartão.
class Flashcard {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.fields,
    this.noteId,
    this.templateId,
    this.cardKind = 'basic',
    this.cardOrdinal = 0,
    this.isArchived = false,
    this.isSuspended = false,
    this.createdAt,
    this.deletedAt,
    this.usn = 0,
  });

  final String id;
  final String deckId;
  final String? noteId;
  final String? templateId;
  final Map<String, dynamic> fields;
  final String cardKind;
  final int cardOrdinal;
  final bool isArchived;
  final bool isSuspended;
  final String? createdAt;
  final String? deletedAt;
  final int usn;

  String get front => (fields['front'] ?? fields['Front'] ?? '').toString();
  String get back => (fields['back'] ?? fields['Back'] ?? '').toString();

  List<String> get tags {
    final raw = fields['tags'];
    if (raw is Iterable) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
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

    return Flashcard(
      id: (json['id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      noteId: json['note_id']?.toString(),
      templateId: json['template_id']?.toString(),
      fields: parsedFields,
      cardKind: (json['card_kind'] ?? json['card_type'] ?? 'basic').toString(),
      cardOrdinal: (json['card_ordinal'] as num?)?.toInt() ?? 0,
      isArchived: json['is_archived'] == true || json['is_archived'] == 1,
      isSuspended: json['is_suspended'] == true || json['is_suspended'] == 1,
      createdAt: json['created_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deck_id': deckId,
      'note_id': noteId,
      'template_id': templateId,
      'fields': fields,
      'card_kind': cardKind,
      'card_ordinal': cardOrdinal,
      'is_archived': isArchived,
      'is_suspended': isSuspended,
      'created_at': createdAt,
      'deleted_at': deletedAt,
      'usn': usn,
    };
  }
}

class Tag {
  const Tag({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    this.createdAt,
    this.usn = 0,
  });

  final String id;
  final String userId;
  final String name;
  final String? color;
  final String? createdAt;
  final int usn;

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      color: json['color']?.toString(),
      createdAt: json['created_at']?.toString(),
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }
}

class CardMedia {
  const CardMedia({
    required this.id,
    required this.cardId,
    required this.storagePath,
    this.storageBucket = 'card-media',
    this.mediaType = 'image',
    this.mimeType,
    this.fileSizeBytes = 0,
    this.fieldName,
    this.sha256Hash,
    this.createdAt,
  });

  final String id;
  final String cardId;
  final String storagePath;
  final String storageBucket;
  final String mediaType;
  final String? mimeType;
  final int fileSizeBytes;
  final String? fieldName;
  final String? sha256Hash;
  final String? createdAt;

  factory CardMedia.fromJson(Map<String, dynamic> json) {
    return CardMedia(
      id: (json['id'] ?? '').toString(),
      cardId: (json['card_id'] ?? '').toString(),
      storagePath: (json['storage_path'] ?? '').toString(),
      storageBucket: (json['storage_bucket'] ?? 'card-media').toString(),
      mediaType: (json['media_type'] ?? 'image').toString(),
      mimeType: json['mime_type']?.toString(),
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      fieldName: json['field_name']?.toString(),
      sha256Hash: json['sha256_hash']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

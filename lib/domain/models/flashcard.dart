import 'dart:convert';

/// Modelos de domínio para Cartões, Tags e Mídias de Cartão.
class Flashcard {
  const Flashcard({
    required this.id,
    required this.deckId,
    this.userId = '',
    required this.fields,
    this.noteId,
    this.templateId,
    this.cardKind = 'basic',
    this.cardOrdinal = 0,
    this.position = 0,
    this.isArchived = false,
    this.isSuspended = false,
    this.isBuried = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.usn = 0,
  });

  final String id;
  final String deckId;
  final String userId;
  final String? noteId;
  final String? templateId;
  final Map<String, dynamic> fields;
  final String cardKind;
  String get cardType => cardKind;
  final int cardOrdinal;
  final int position;
  final bool isArchived;
  final bool isSuspended;
  final bool isBuried;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int usn;

  String get front =>
      (fields['front'] ?? fields['Front'] ?? fields['text'] ?? fields['Text'] ?? '')
          .toString();

  String get back =>
      (fields['back'] ?? fields['Back'] ?? fields['extra'] ?? fields['Extra'] ?? '')
          .toString();

  String? get extra => fields['extra']?.toString();

  List<String> get tags {
    final dynamic raw = fields['tags'];
    if (raw is Iterable) {
      return raw.map((dynamic e) => e.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? userId,
    String? noteId,
    String? templateId,
    Map<String, dynamic>? fields,
    String? cardKind,
    String? cardType,
    int? cardOrdinal,
    int? position,
    bool? isArchived,
    bool? isSuspended,
    bool? isBuried,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    int? usn,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      templateId: templateId ?? this.templateId,
      fields: fields ?? this.fields,
      cardKind: cardKind ?? cardType ?? this.cardKind,
      cardOrdinal: cardOrdinal ?? this.cardOrdinal,
      position: position ?? this.position,
      isArchived: isArchived ?? this.isArchived,
      isSuspended: isSuspended ?? this.isSuspended,
      isBuried: isBuried ?? this.isBuried,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      usn: usn ?? this.usn,
    );
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
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

    if (parsedFields.isEmpty) {
      parsedFields = <String, dynamic>{
        if (json['front'] != null) 'front': json['front'],
        if (json['back'] != null) 'back': json['back'],
        if (json['extra'] != null) 'extra': json['extra'],
      };
    }

    return Flashcard(
      id: (json['id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      noteId: json['note_id']?.toString(),
      templateId: json['template_id']?.toString(),
      fields: parsedFields,
      cardKind:
          (json['card_kind'] ?? json['card_type'] ?? 'basic').toString(),
      cardOrdinal:
          (json['card_ordinal'] ?? json['card_ord'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt() ?? 0,
      isArchived: json['is_archived'] == true || json['is_archived'] == 1,
      isSuspended: json['is_suspended'] == true || json['is_suspended'] == 1,
      isBuried: json['is_buried'] == true || json['is_buried'] == 1,
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
      'note_id': noteId,
      'template_id': templateId,
      'fields': fields,
      'field_values': fields,
      'front': front,
      'back': back,
      if (extra != null) 'extra': extra,
      'card_kind': cardKind,
      'card_type': cardKind,
      'card_ordinal': cardOrdinal,
      'card_ord': cardOrdinal,
      'position': position,
      'is_archived': isArchived,
      'is_suspended': isSuspended,
      'is_buried': isBuried,
      'created_at': createdAt,
      'updated_at': updatedAt,
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'name': name,
        'color': color,
        'created_at': createdAt,
        'usn': usn,
      };
}

class CardMedia {
  const CardMedia({
    required this.id,
    required this.cardId,
    this.userId = '',
    required this.storagePath,
    this.storageBucket = 'card-media',
    this.mediaType = 'image',
    this.mimeType,
    int? fileSizeBytes,
    int? sizeBytes,
    this.fieldName,
    this.fieldSide = 'front',
    String? fileName,
    this.sha256Hash,
    this.createdAt,
  })  : fileSizeBytes = fileSizeBytes ?? sizeBytes ?? 0,
        fileName = fileName ?? '';

  final String id;
  final String cardId;
  final String userId;
  final String storagePath;
  final String storageBucket;
  final String mediaType;
  final String? mimeType;
  final int fileSizeBytes;
  int get sizeBytes => fileSizeBytes;
  final String? fieldName;
  final String fieldSide;
  final String fileName;
  final String? sha256Hash;
  final String? createdAt;

  factory CardMedia.fromJson(Map<String, dynamic> json) {
    final String path = (json['storage_path'] ?? '').toString();
    final String fName = (json['file_name'] ??
            (path.contains('/') ? path.split('/').last : 'media.bin'))
        .toString();

    return CardMedia(
      id: (json['id'] ?? '').toString(),
      cardId: (json['card_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      storagePath: path,
      storageBucket: (json['storage_bucket'] ?? 'card-media').toString(),
      mediaType: (json['media_type'] ?? 'image').toString(),
      mimeType: json['mime_type']?.toString(),
      fileSizeBytes:
          (json['file_size_bytes'] ?? json['size_bytes'] as num?)?.toInt() ?? 0,
      fieldName: (json['field_name'] ?? json['field_side'])?.toString(),
      fieldSide: (json['field_side'] ?? json['field_name'] ?? 'front').toString(),
      fileName: fName,
      sha256Hash: (json['sha256_hash'] ?? json['checksum'])?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'card_id': cardId,
        'user_id': userId,
        'storage_path': storagePath,
        'storage_bucket': storageBucket,
        'media_type': mediaType,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'size_bytes': fileSizeBytes,
        'field_name': fieldName,
        'field_side': fieldSide,
        'file_name': fileName,
        'sha256_hash': sha256Hash,
        'created_at': createdAt,
      };
}

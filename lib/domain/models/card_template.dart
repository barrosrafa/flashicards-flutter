/// Modelos de domínio para Templates de Cartão (`card_templates`).
class TemplateField {
  const TemplateField({
    required this.name,
    this.type = 'text',
  });

  final String name;
  final String type; // 'text' | 'image' | 'audio' | 'cloze'

  factory TemplateField.fromJson(Map<String, dynamic> json) {
    return TemplateField(
      name: (json['name'] ?? '').toString().trim(),
      type: (json['type'] ?? 'text').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'type': type};
}

class CardGenerationRule {
  const CardGenerationRule({
    required this.front,
    required this.back,
    this.name,
  });

  final String? name;
  final String front;
  final String back;

  factory CardGenerationRule.fromJson(Map<String, dynamic> json) {
    return CardGenerationRule(
      name: json['name']?.toString(),
      front: (json['front'] ?? '').toString(),
      back: (json['back'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'front': front,
        'back': back,
      };
}

class RenderedCard {
  const RenderedCard({
    required this.front,
    required this.back,
    this.name,
  });

  final String? name;
  final String front;
  final String back;
}

class CardTemplate {
  const CardTemplate({
    required this.id,
    required this.name,
    required this.fieldDefinitions,
    required this.cardGeneration,
    this.userId,
    this.isSystem = false,
    this.usn = 0,
  });

  final String id;
  final String name;
  final String? userId;
  final bool isSystem;
  final List<TemplateField> fieldDefinitions;
  final List<CardGenerationRule> cardGeneration;
  final int usn;

  factory CardTemplate.fromJson(Map<String, dynamic> json) {
    final rawFields = json['field_definitions'];
    final rawGen = json['card_generation'];
    return CardTemplate(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Modelo Básico').toString(),
      userId: json['user_id']?.toString(),
      isSystem: json['is_system'] == true || json['is_system'] == 1,
      fieldDefinitions: rawFields is Iterable
          ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(TemplateField.fromJson)
              .where((f) => f.name.isNotEmpty)
              .toList(growable: false)
          : const [],
      cardGeneration: rawGen is Iterable
          ? rawGen
              .whereType<Map<String, dynamic>>()
              .map(CardGenerationRule.fromJson)
              .toList(growable: false)
          : const [],
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'user_id': userId,
        'is_system': isSystem,
        'field_definitions': fieldDefinitions.map((f) => f.toJson()).toList(),
        'card_generation': cardGeneration.map((g) => g.toJson()).toList(),
        'usn': usn,
      };
}

/// Modelos de domínio para Templates de Cartão (`card_templates`).
class TemplateField {
  const TemplateField({
    required this.name,
    this.type = 'text',
    this.description,
  });

  final String name;
  final String type; // 'text' | 'image' | 'audio' | 'cloze'
  final String? description;

  factory TemplateField.fromJson(Map<String, dynamic> json) {
    return TemplateField(
      name: (json['name'] ?? '').toString().trim(),
      type: (json['type'] ?? 'text').toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'type': type,
        if (description != null) 'description': description,
      };
}

class CardGenerationRule {
  const CardGenerationRule({
    this.name,
    String? front,
    String? back,
    String? frontTemplate,
    String? backTemplate,
  })  : _front = frontTemplate ?? front ?? '',
        _back = backTemplate ?? back ?? '';

  final String? name;
  final String _front;
  final String _back;

  String get front => _front;
  String get back => _back;
  String get frontTemplate => _front;
  String get backTemplate => _back;

  factory CardGenerationRule.fromJson(Map<String, dynamic> json) {
    return CardGenerationRule(
      name: json['name']?.toString(),
      frontTemplate: (json['frontTemplate'] ?? json['front_template'] ?? json['front'] ?? '').toString(),
      backTemplate: (json['backTemplate'] ?? json['back_template'] ?? json['back'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (name != null) 'name': name,
        'front': _front,
        'back': _back,
        'front_template': _front,
        'back_template': _back,
      };
}

class RenderedCard {
  const RenderedCard({
    String? front,
    String? back,
    String? frontHtml,
    String? backHtml,
    String? name,
    String? ruleName,
  })  : frontHtml = frontHtml ?? front ?? '',
        backHtml = backHtml ?? back ?? '',
        ruleName = ruleName ?? name;

  final String frontHtml;
  final String backHtml;
  final String? ruleName;

  String get front => frontHtml;
  String get back => backHtml;
  String? get name => ruleName;
}

class CardTemplate {
  const CardTemplate({
    required this.id,
    required this.name,
    required this.fieldDefinitions,
    required this.cardGeneration,
    this.userId,
    this.isSystem = false,
    this.css = '',
    this.usn = 0,
  });

  final String id;
  final String name;
  final String? userId;
  final bool isSystem;
  final String css;
  final List<TemplateField> fieldDefinitions;
  final List<CardGenerationRule> cardGeneration;
  final int usn;

  factory CardTemplate.fromJson(Map<String, dynamic> json) {
    final dynamic rawFields = json['field_definitions'] ?? json['fieldDefinitions'];
    final dynamic rawGen = json['card_generation'] ?? json['cardGeneration'];
    return CardTemplate(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Modelo Básico').toString(),
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      isSystem: json['is_system'] == true || json['is_system'] == 1 || json['isSystem'] == true,
      css: (json['css'] ?? '').toString(),
      fieldDefinitions: rawFields is Iterable
          ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(TemplateField.fromJson)
              .where((TemplateField f) => f.name.isNotEmpty)
              .toList(growable: false)
          : const <TemplateField>[],
      cardGeneration: rawGen is Iterable
          ? rawGen
              .whereType<Map<String, dynamic>>()
              .map(CardGenerationRule.fromJson)
              .toList(growable: false)
          : const <CardGenerationRule>[],
      usn: int.tryParse((json['usn'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'user_id': userId,
        'is_system': isSystem,
        'css': css,
        'field_definitions': fieldDefinitions.map((TemplateField f) => f.toJson()).toList(),
        'card_generation': cardGeneration.map((CardGenerationRule g) => g.toJson()).toList(),
        'usn': usn,
      };
}

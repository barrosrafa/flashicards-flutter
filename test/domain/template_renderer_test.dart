import 'package:flashi_mobile/domain/models/card_template.dart';
import 'package:flashi_mobile/domain/services/template_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TemplateRenderer', () {
    test('extracts distinct sorted cloze indices', () {
      const String text =
          'A {{c2::mitocondria}} produz {{c1::ATP::energia}} na {{c1::celula}}.';
      expect(TemplateRenderer.extractClozeIndices(text), <int>[1, 2]);
    });

    test('renders positive and negative conditional blocks and FrontSide', () {
      const Map<String, String> fields = <String, String>{
        'Front': 'O que e FSRS-6?',
        'Back': 'Algoritmo de repeticao espacada de 21 pesos.',
        'Extra': 'Criado por Jarrett Ye.',
      };

      final List<RenderedCard> cards = TemplateRenderer.renderCards(
        fields: fields,
        rules: const <CardGenerationRule>[
          CardGenerationRule(
            name: 'Basic',
            frontTemplate: '{{Front}}{{#Hint}} ({{Hint}}){{/Hint}}',
            backTemplate:
                '{{FrontSide}}\n---\n{{Back}}\n{{#Extra}}Nota: {{Extra}}{{/Extra}}',
          ),
        ],
      );

      expect(cards, hasLength(1));
      expect(cards.first.frontHtml, 'O que e FSRS-6?');
      expect(
        cards.first.backHtml,
        contains('Algoritmo de repeticao espacada de 21 pesos.'),
      );
      expect(cards.first.backHtml, contains('Nota: Criado por Jarrett Ye.'));
    });

    test('generates one card per cloze index', () {
      const Map<String, String> fields = <String, String>{
        'Text': 'O {{c1::coracao}} bombeia {{c2::sangue}}.',
        'Extra': 'Sistema cardiovascular',
      };

      final List<RenderedCard> cards = TemplateRenderer.renderCards(
        fields: fields,
        rules: const <CardGenerationRule>[
          CardGenerationRule(
            name: 'Cloze',
            frontTemplate: '{{cloze:Text}}',
            backTemplate: '{{cloze:Text}}\n{{Extra}}',
          ),
        ],
        isCloze: true,
      );

      expect(cards, hasLength(2));
      expect(cards[0].frontHtml, 'O [...] bombeia sangue.');
      expect(cards[0].backHtml, contains('O **[coracao]** bombeia sangue.'));
      expect(cards[1].frontHtml, 'O coracao bombeia [...].');
      expect(cards[1].backHtml, contains('O coracao bombeia **[sangue]**.'));
    });
  });
}

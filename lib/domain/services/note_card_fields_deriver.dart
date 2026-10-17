import '../models/note.dart';
import 'template_renderer.dart';

/// Derives generated card definitions (front/back pairs and ordinals) from a [NoteInput].
///
/// Mirrors `src/lib/services/note-card-fields.ts` from `app-flashi`.
class DerivedCardDefinition {
  const DerivedCardDefinition({
    required this.ord,
    required this.cardType,
    required this.front,
    required this.back,
    this.extra,
  });

  final int ord;
  final String cardType;
  final String front;
  final String back;
  final String? extra;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ord': ord,
      'card_type': cardType,
      'front': front,
      'back': back,
      if (extra != null) 'extra': extra,
    };
  }
}

class NoteCardFieldsDeriver {
  const NoteCardFieldsDeriver._();

  /// Derives concrete cards for `basic`, `reversed`, `cloze`, or `image_occlusion` notes.
  static List<DerivedCardDefinition> deriveCards(NoteInput input) {
    final String modelKind = input.modelKind.toLowerCase();
    final Map<String, String> fields = input.fieldValues;

    final String front =
        (fields['front'] ?? fields['Front'] ?? fields['text'] ?? fields['Text'] ?? '')
            .trim();
    final String back =
        (fields['back'] ?? fields['Back'] ?? fields['extra'] ?? fields['Extra'] ?? '')
            .trim();
    final String extra = (fields['extra'] ?? fields['Extra'] ?? '').trim();

    if (modelKind == 'cloze') {
      final String sourceText = front.isNotEmpty ? front : back;
      final List<int> indices = TemplateRenderer.extractClozeIndices(sourceText);
      final List<int> effectiveIndices =
          indices.isEmpty ? const <int>[1] : indices;

      return effectiveIndices.map((int clozeIndex) {
        final String renderedFront = TemplateRenderer.renderClozeText(
          rawText: sourceText,
          activeClozeIndex: clozeIndex,
          revealAnswer: false,
        );
        final String renderedBack = TemplateRenderer.renderClozeText(
          rawText: sourceText,
          activeClozeIndex: clozeIndex,
          revealAnswer: true,
        );
        final String fullBack = extra.isNotEmpty
            ? '$renderedBack\n\n$extra'
            : (back.isNotEmpty && back != sourceText
                ? '$renderedBack\n\n$back'
                : renderedBack);

        return DerivedCardDefinition(
          ord: clozeIndex - 1,
          cardType: 'cloze',
          front: renderedFront,
          back: fullBack,
          extra: extra.isEmpty ? null : extra,
        );
      }).toList(growable: false);
    }

    if (modelKind == 'reversed' || modelKind == 'basic_reversed') {
      final List<DerivedCardDefinition> cards = <DerivedCardDefinition>[
        DerivedCardDefinition(
          ord: 0,
          cardType: 'basic',
          front: front,
          back: back,
          extra: extra.isEmpty ? null : extra,
        ),
      ];
      if (back.isNotEmpty) {
        cards.add(
          DerivedCardDefinition(
            ord: 1,
            cardType: 'reversed',
            front: back,
            back: front,
            extra: extra.isEmpty ? null : extra,
          ),
        );
      }
      return cards;
    }

    return <DerivedCardDefinition>[
      DerivedCardDefinition(
        ord: 0,
        cardType: modelKind == 'image_occlusion' ? 'image_occlusion' : 'basic',
        front: front,
        back: back,
        extra: extra.isEmpty ? null : extra,
      ),
    ];
  }

  /// Extracts parsed [NoteClozeDeletion] items from a cloze text.
  static List<NoteClozeDeletion> extractClozeDeletions(String sourceText) {
    final RegExp regex = RegExp(r'\{\{c(\d+)::([\s\S]*?)(?:::([\s\S]*?))?\}\}');
    final List<NoteClozeDeletion> deletions = <NoteClozeDeletion>[];

    for (final RegExpMatch match in regex.allMatches(sourceText)) {
      final int index = int.tryParse(match.group(1) ?? '1') ?? 1;
      final String targetText = (match.group(2) ?? '').trim();
      final String? hint = match.group(3)?.trim();
      if (targetText.isNotEmpty) {
        deletions.add(
          NoteClozeDeletion(
            clozeIndex: index,
            targetText: targetText,
            hintText: (hint == null || hint.isEmpty) ? null : hint,
          ),
        );
      }
    }
    return deletions;
  }
}

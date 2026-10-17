import 'dart:math' as math;

/// Modelos de domínio para Oclusão de Imagem (`OcclusionMask` e `OcclusionCreationResult`).
///
/// Coordenadas sempre são percentuais canônicos (0 a 100): 30 significa 30%.
class OcclusionMask {
  const OcclusionMask({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.id,
    this.label,
    this.clozeOrdinal,
  });

  final String? id;
  final double x;
  final double y;
  final double w;
  final double h;
  final String? label;
  final int? clozeOrdinal;

  double get width => w;
  double get height => h;

  static double _round3(double val) => (val * 1000).round() / 1000.0;

  static double clampPercentage(double val) => val.clamp(0.0, 100.0);

  bool get hasMinimumArea => w > 0.2 && h > 0.2 && (w * h) >= 0.5;

  static OcclusionMask fromNormalizedDrag({
    required String id,
    required double startXPercent,
    required double startYPercent,
    required double endXPercent,
    required double endYPercent,
    String? label,
    int? clozeOrdinal,
  }) {
    final double left = math.min(startXPercent, endXPercent).clamp(0.0, 100.0);
    final double top = math.min(startYPercent, endYPercent).clamp(0.0, 100.0);
    final double right = math.max(startXPercent, endXPercent).clamp(0.0, 100.0);
    final double bottom = math.max(startYPercent, endYPercent).clamp(0.0, 100.0);

    return OcclusionMask(
      id: id,
      x: _round3(left),
      y: _round3(top),
      w: _round3(right - left),
      h: _round3(bottom - top),
      label: label,
      clozeOrdinal: clozeOrdinal,
    );
  }

  OcclusionMask normalized({String unit = 'percent', int? fallbackOrdinal}) {
    final double scale = unit == 'fraction' ? 100.0 : 1.0;
    return OcclusionMask(
      id: id,
      x: _round3(x * scale),
      y: _round3(y * scale),
      w: _round3(w * scale),
      h: _round3(h * scale),
      label: label,
      clozeOrdinal: clozeOrdinal ?? fallbackOrdinal,
    );
  }

  bool get isValidPercentage =>
      x.isFinite &&
      y.isFinite &&
      w.isFinite &&
      h.isFinite &&
      x >= 0 &&
      y >= 0 &&
      w > 0 &&
      h > 0 &&
      (x + w) <= 100.001 &&
      (y + h) <= 100.001;

  OcclusionMask copyWith({
    String? id,
    double? x,
    double? y,
    double? w,
    double? h,
    String? label,
    int? clozeOrdinal,
  }) {
    return OcclusionMask(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      label: label ?? this.label,
      clozeOrdinal: clozeOrdinal ?? this.clozeOrdinal,
    );
  }

  factory OcclusionMask.fromJson(Map<String, dynamic> json) {
    return OcclusionMask(
      id: json['id']?.toString(),
      x: (json['x'] ?? json['x_pos'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] ?? json['y_pos'] as num?)?.toDouble() ?? 0.0,
      w: (json['w'] ?? json['width'] ?? json['width_pct'] as num?)?.toDouble() ?? 10.0,
      h: (json['h'] ?? json['height'] ?? json['height_pct'] as num?)?.toDouble() ?? 10.0,
      label: (json['label'] ?? json['label_text'])?.toString(),
      clozeOrdinal: (json['cloze_ordinal'] ?? json['clozeOrdinal'] as num?)?.toInt(),
    ).normalized();
  }

  factory OcclusionMask.fromDatabaseRow(Map<String, dynamic> row) {
    return OcclusionMask.fromJson(row);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'x': x,
      'y': y,
      'w': w,
      'h': h,
      'width': w,
      'height': h,
      'x_pos': x,
      'y_pos': y,
      'width_pct': w,
      'height_pct': h,
      if (label != null) 'label': label,
      if (label != null) 'label_text': label,
      if (clozeOrdinal != null) 'cloze_ordinal': clozeOrdinal,
    };
  }

  Map<String, dynamic> toRpcBoxJson(int index) {
    final OcclusionMask norm = normalized(fallbackOrdinal: index + 1);
    return <String, dynamic>{
      'cloze_ordinal': norm.clozeOrdinal ?? (index + 1),
      'label_text': norm.label,
      'x_pos': norm.x,
      'y_pos': norm.y,
      'width_pct': norm.w,
      'height_pct': norm.h,
      'metadata': const <String, dynamic>{},
    };
  }
}

class OcclusionCreationResult {
  const OcclusionCreationResult({
    required this.noteId,
    this.cardIds = const <String>[],
    this.cards = const <({String cardId, int clozeOrdinal})>[],
    this.masks = const <OcclusionMask>[],
    this.status = 'success',
    this.code = 'OK',
    this.requestId = '',
    this.assetId,
    this.deckId,
  });

  final String noteId;
  final List<String> cardIds;
  final List<({String cardId, int clozeOrdinal})> cards;
  final String? assetId;
  final String? deckId;
  final List<OcclusionMask> masks;
  final String status;
  final String code;
  final String requestId;

  List<String> get effectiveCardIds => cardIds.isNotEmpty
      ? cardIds
      : cards.map((({String cardId, int clozeOrdinal}) c) => c.cardId).toList(growable: false);

  factory OcclusionCreationResult.fromJson(Map<String, dynamic> json) {
    final dynamic rawCards = json['cards'];
    final List<({String cardId, int clozeOrdinal})> parsedCards = <({String cardId, int clozeOrdinal})>[];
    final List<String> parsedCardIds = <String>[];

    if (rawCards is Iterable) {
      for (final dynamic item in rawCards) {
        if (item is Map) {
          final String cid = (item['card_id'] ?? item['cardId'] ?? item['id'] ?? '').toString();
          final int ord = int.tryParse((item['cloze_ordinal'] ?? item['clozeOrdinal'] ?? '1').toString()) ?? 1;
          if (cid.isNotEmpty) {
            parsedCards.add((cardId: cid, clozeOrdinal: ord));
            parsedCardIds.add(cid);
          }
        } else if (item is String) {
          parsedCardIds.add(item);
        }
      }
    }

    final dynamic rawCardIds = json['card_ids'] ?? json['cardIds'];
    if (rawCardIds is Iterable) {
      for (final dynamic item in rawCardIds) {
        final String s = item.toString();
        if (s.isNotEmpty && !parsedCardIds.contains(s)) {
          parsedCardIds.add(s);
        }
      }
    }

    final dynamic rawMasks = json['masks'];
    final List<OcclusionMask> parsedMasks = rawMasks is Iterable
        ? rawMasks
            .whereType<Map<String, dynamic>>()
            .map(OcclusionMask.fromJson)
            .toList(growable: false)
        : const <OcclusionMask>[];

    return OcclusionCreationResult(
      noteId: (json['note_id'] ?? json['noteId'] ?? '').toString(),
      cardIds: parsedCardIds,
      cards: parsedCards,
      masks: parsedMasks,
      status: (json['status'] ?? 'success').toString(),
      code: (json['code'] ?? 'OK').toString(),
      requestId: (json['request_id'] ?? json['requestId'] ?? '').toString(),
      assetId: json['asset_id']?.toString() ?? json['assetId']?.toString(),
      deckId: json['deck_id']?.toString() ?? json['deckId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'note_id': noteId,
        'card_ids': effectiveCardIds,
        'status': status,
        'code': code,
        'request_id': requestId,
        if (assetId != null) 'asset_id': assetId,
        if (deckId != null) 'deck_id': deckId,
        'masks': masks.map((OcclusionMask m) => m.toJson()).toList(),
      };
}

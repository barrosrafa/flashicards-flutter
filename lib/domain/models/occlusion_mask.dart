/// Modelos de domínio para Oclusão de Imagem (`OcclusionMask` e `OcclusionCreationResult`).
///
/// Coordenadas sempre são percentuais canônicos (0 a 100): 30 significa 30%.
class OcclusionMask {
  const OcclusionMask({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.label,
    this.clozeOrdinal,
  });

  final double x;
  final double y;
  final double w;
  final double h;
  final String? label;
  final int? clozeOrdinal;

  static double _round3(double val) => (val * 1000).round() / 1000.0;

  OcclusionMask normalized({String unit = 'percent', int? fallbackOrdinal}) {
    final scale = unit == 'fraction' ? 100.0 : 1.0;
    return OcclusionMask(
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
      (x + w) <= 100.0 &&
      (y + h) <= 100.0;

  OcclusionMask copyWith({
    double? x,
    double? y,
    double? w,
    double? h,
    String? label,
    int? clozeOrdinal,
  }) {
    return OcclusionMask(
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      label: label ?? this.label,
      clozeOrdinal: clozeOrdinal ?? this.clozeOrdinal,
    );
  }

  factory OcclusionMask.fromDatabaseRow(Map<String, dynamic> row) {
    return OcclusionMask(
      x: (row['x_pos'] as num?)?.toDouble() ?? 0,
      y: (row['y_pos'] as num?)?.toDouble() ?? 0,
      w: (row['width_pct'] as num?)?.toDouble() ?? 10,
      h: (row['height_pct'] as num?)?.toDouble() ?? 10,
      label: row['label_text']?.toString(),
      clozeOrdinal: (row['cloze_ordinal'] as num?)?.toInt(),
    ).normalized();
  }

  Map<String, dynamic> toRpcBoxJson(int index) {
    final norm = normalized(fallbackOrdinal: index + 1);
    return {
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
    required this.cards,
    required this.noteId,
    required this.masks,
    required this.status,
    required this.code,
    required this.requestId,
    this.assetId,
    this.deckId,
  });

  final List<({String cardId, int clozeOrdinal})> cards;
  final String? assetId;
  final String noteId;
  final String? deckId;
  final List<OcclusionMask> masks;
  final String status;
  final String code;
  final String requestId;
}

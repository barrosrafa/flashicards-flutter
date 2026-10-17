import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/crypto_utils.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../domain/models/deck.dart';
import '../../../domain/models/occlusion_mask.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Multi-Touch Image Occlusion Editor (`/occlusion`) that normalizes drawn
/// rectangular masks to `[0..100]` percentage coordinates (`OcclusionMask.clampPercentage`)
/// and creates 1 flashcard per mask via `OcclusionRepository`.
///
/// Mirrors `src/components/occlusion/image-occlusion-modal.tsx` from `app-flashi`.
class ImageOcclusionEditorScreen extends StatefulWidget {
  const ImageOcclusionEditorScreen({super.key});

  @override
  State<ImageOcclusionEditorScreen> createState() =>
      _ImageOcclusionEditorScreenState();
}

class _ImageOcclusionEditorScreenState
    extends State<ImageOcclusionEditorScreen> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Anatomia Cardiopulmonar',
  );
  final List<OcclusionMask> _masks = <OcclusionMask>[
    const OcclusionMask(
      id: 'mask-1',
      x: 14,
      y: 18,
      width: 28,
      height: 18,
      label: 'Arco Aortico',
    ),
    const OcclusionMask(
      id: 'mask-2',
      x: 54,
      y: 44,
      width: 30,
      height: 20,
      label: 'Ventriculo Esquerdo',
    ),
  ];

  List<Deck> _decks = const <Deck>[];
  String? _selectedDeckId;
  Offset? _dragStartNormalized;
  Offset? _dragCurrentNormalized;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final List<Deck> decks =
        await locator.deckRepository.listDecks(userId: locator.activeUserId);
    if (!mounted) {
      return;
    }
    setState(() {
      _decks = decks;
      if (decks.isNotEmpty) {
        _selectedDeckId = decks.first.id;
      }
    });
  }

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    final double xPct = (details.localPosition.dx / canvasSize.width) * 100.0;
    final double yPct = (details.localPosition.dy / canvasSize.height) * 100.0;
    setState(() {
      _dragStartNormalized = Offset(
        OcclusionMask.clampPercentage(xPct),
        OcclusionMask.clampPercentage(yPct),
      );
      _dragCurrentNormalized = _dragStartNormalized;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    final double xPct = (details.localPosition.dx / canvasSize.width) * 100.0;
    final double yPct = (details.localPosition.dy / canvasSize.height) * 100.0;
    setState(() {
      _dragCurrentNormalized = Offset(
        OcclusionMask.clampPercentage(xPct),
        OcclusionMask.clampPercentage(yPct),
      );
    });
  }

  void _onPanEnd() {
    final Offset? start = _dragStartNormalized;
    final Offset? end = _dragCurrentNormalized;
    setState(() {
      _dragStartNormalized = null;
      _dragCurrentNormalized = null;
    });
    if (start == null || end == null) {
      return;
    }

    final OcclusionMask candidate = OcclusionMask.fromNormalizedDrag(
      id: CryptoUtils.generateUuidV4(),
      startXPercent: start.dx,
      startYPercent: start.dy,
      endXPercent: end.dx,
      endYPercent: end.dy,
      label: 'Estrutura #${_masks.length + 1}',
    );

    if (candidate.hasMinimumArea) {
      HapticsHelper.mediumImpact();
      setState(() {
        _masks.add(candidate);
      });
    }
  }

  Future<void> _saveOcclusionCards() async {
    if (_masks.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      final ServiceLocator locator = ServiceLocator.instance;
      String targetDeckId = _selectedDeckId ?? '';
      if (targetDeckId.isEmpty) {
        final Deck created = await locator.deckRepository.createDeck(
          userId: locator.activeUserId,
          title: 'Deck de Oclusao Visual',
        );
        targetDeckId = created.id;
      }

      final OcclusionCreationResult result =
          await locator.occlusionRepository.createImageOcclusionNote(
        userId: locator.activeUserId,
        deckId: targetDeckId,
        fileName: 'diagram.png',
        mimeType: 'image/png',
        imageBytes: Uint8List.fromList(<int>[137, 80, 78, 71]),
        masks: _masks,
        title: _titleController.text,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Criados ${result.cardIds.length} cartoes de oclusao (1 por mascara)!',
          ),
        ),
      );
      context.go('/decks/$targetDeckId');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/tools'),
            ),
            Expanded(
              child: Text(
                'Oclusao de Imagem Multi-Toque',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Arraste sobre o diagrama abaixo para desenhar mascaras normalizadas (0..100%). Cada mascara gera 1 cartao FSRS-6.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),

        FuturisticFormField(
          label: 'Titulo do Diagrama / Imagem',
          controller: _titleController,
        ),
        const SizedBox(height: 14),

        if (_decks.isNotEmpty) ...<Widget>[
          DropdownButtonFormField<String>(
            initialValue: _selectedDeckId,
            decoration: const InputDecoration(labelText: 'Baralho de Destino'),
            items: _decks
                .map(
                  (Deck d) => DropdownMenuItem<String>(
                    value: d.id,
                    child: Text(d.title),
                  ),
                )
                .toList(),
            onChanged: (String? v) => setState(() => _selectedDeckId = v),
          ),
          const SizedBox(height: 16),
        ],

        // Interactive Normalized [0..100] Percentage Canvas
        GlassBentoCard(
          padding: const EdgeInsets.all(12),
          accentBorderColor: colors.accentCyan.withValues(alpha: 0.45),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Size canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return GestureDetector(
                  onPanStart: (DragStartDetails d) =>
                      _onPanStart(d, canvasSize),
                  onPanUpdate: (DragUpdateDetails d) =>
                      _onPanUpdate(d, canvasSize),
                  onPanEnd: (_) => _onPanEnd(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.bgCanvas,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderSpecular),
                    ),
                    child: Stack(
                      children: <Widget>[
                        // Background anatomical schematic grid
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.monitor_heart_rounded,
                                size: 54,
                                color: colors.accentViolet.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Arraste o dedo para desenhar nova mascara',
                                style: FlashiTypography.monoMetric(
                                  color: colors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Existing Masks
                        ..._masks.asMap().entries.map(
                          (MapEntry<int, OcclusionMask> entry) {
                            final int idx = entry.key;
                            final OcclusionMask m = entry.value;
                            return Positioned(
                              left: (m.x / 100.0) * canvasSize.width,
                              top: (m.y / 100.0) * canvasSize.height,
                              width: (m.width / 100.0) * canvasSize.width,
                              height: (m.height / 100.0) * canvasSize.height,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _masks.removeAt(idx));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colors.accentCyan
                                        .withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colors.accentCyan,
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    '#${idx + 1} ${m.label ?? ""}',
                                    overflow: TextOverflow.ellipsis,
                                    style: FlashiTypography.monoMetric(
                                      color: colors.textPrimary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Mascaras Ativas (${_masks.length}) · Toque em uma mascara para remover',
          style: FlashiTypography.monoMetric(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 16),

        CyberPrimaryButton(
          label: 'Gerar ${_masks.length} Cartoes de Oclusao',
          icon: Icons.layers_rounded,
          isLoading: _saving,
          fullWidth: true,
          onPressed: _saveOcclusionCards,
        ),
      ],
    );
  }
}

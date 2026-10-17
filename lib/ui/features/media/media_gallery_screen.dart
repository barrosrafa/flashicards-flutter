import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/storage_buckets.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/models/flashcard.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Media Gallery & Quota Manager (`/media`) for the `card-media` private bucket.
///
/// Mirrors `src/lib/services/media-service.ts` from `app-flashi`.
class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  List<CardMedia> _mediaItems = const <CardMedia>[];

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final List<CardMedia> list = await locator.mediaRepository
        .listMedia(userId: locator.activeUserId);
    if (!mounted) {
      return;
    }
    setState(() => _mediaItems = list);
  }

  Future<void> _addSampleMedia() async {
    final ServiceLocator locator = ServiceLocator.instance;
    await locator.mediaRepository.uploadCardMedia(
      userId: locator.activeUserId,
      cardId: 'sample-card',
      fileName: 'neuro-synapse-diagram.webp',
      mimeType: 'image/webp',
      bytes: Uint8List.fromList(List<int>.filled(2048, 42)),
    );
    await _loadMedia();
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final int totalBytes = _mediaItems.fold<int>(
      0,
      (int sum, CardMedia m) => sum + m.sizeBytes,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/profile'),
            ),
            Expanded(
              child: Text(
                'Galeria de Midia (card-media)',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        GlassBentoCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'QUOTA DO BUCKET PRIVADO',
                    style: FlashiTypography.monoMetric(
                      color: colors.accentCyan,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(totalBytes / 1024).toStringAsFixed(1)} KB / ${(StorageBuckets.userTotalQuotaBytes / (1024 * 1024)).round()} MB',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              CyberPrimaryButton(
                label: 'Novo Upload',
                icon: Icons.cloud_upload_rounded,
                onPressed: _addSampleMedia,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ..._mediaItems.map(
          (CardMedia m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassBentoCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Icon(Icons.image_rounded, color: colors.accentCyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          m.fileName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${m.mimeType} · ${(m.sizeBytes / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

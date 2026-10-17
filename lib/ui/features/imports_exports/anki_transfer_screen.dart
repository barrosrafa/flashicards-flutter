import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/anki_transfer.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Anki `.apkg` / `.colpkg` Import & Export screen (`/anki`).
///
/// Mirrors `src/app/anki/page.tsx` from `app-flashi`.
class AnkiTransferScreen extends StatefulWidget {
  const AnkiTransferScreen({super.key});

  @override
  State<AnkiTransferScreen> createState() => _AnkiTransferScreenState();
}

class _AnkiTransferScreenState extends State<AnkiTransferScreen> {
  bool _includeScheduling = true;
  bool _includeMedia = true;
  bool _busy = false;
  AnkiImportResult? _importResult;
  AnkiExportResult? _exportResult;

  Future<void> _triggerAnkiImport() async {
    setState(() => _busy = true);
    try {
      final ServiceLocator locator = ServiceLocator.instance;
      final AnkiImportResult res =
          await locator.ankiTransferRepository.importAnkiPackage(
        userId: locator.activeUserId,
        fileName: 'medical-collection.apkg',
        bytes: Uint8List.fromList(<int>[80, 75, 3, 4]),
        includeScheduling: _includeScheduling,
      );
      if (!mounted) {
        return;
      }
      setState(() => _importResult = res);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _triggerAnkiExport() async {
    setState(() => _busy = true);
    try {
      final ServiceLocator locator = ServiceLocator.instance;
      final AnkiExportResult res =
          await locator.ankiTransferRepository.exportAnkiPackage(
        userId: locator.activeUserId,
        includeScheduling: _includeScheduling,
        includeMedia: _includeMedia,
      );
      if (!mounted) {
        return;
      }
      setState(() => _exportResult = res);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
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
                'Transferencia Anki (.apkg / .colpkg)',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Compatibilidade bidirecional 100% com Anki Desktop e AnkiDroid preservando modelos Cloze, midias e historico de revisoes.',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),

        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Preservar agendamento e revisoes FSRS'),
                value: _includeScheduling,
                onChanged: (bool v) => setState(() => _includeScheduling = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Incluir arquivos de midia (imagens/audio)'),
                value: _includeMedia,
                onChanged: (bool v) => setState(() => _includeMedia = v),
              ),
              const SizedBox(height: 12),
              CyberPrimaryButton(
                label: 'Importar Pacote .apkg / .colpkg',
                icon: Icons.file_download_rounded,
                isLoading: _busy,
                fullWidth: true,
                onPressed: _triggerAnkiImport,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.borderSpecular),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _busy ? null : _triggerAnkiExport,
                icon: Icon(Icons.ios_share_rounded, color: colors.accentCyan),
                label: Text(
                  'Exportar Colecao para .apkg',
                  style: TextStyle(color: colors.textPrimary),
                ),
              ),
            ],
          ),
        ),

        if (_importResult != null) ...<Widget>[
          const SizedBox(height: 14),
          GlassBentoCard(
            accentBorderColor: colors.ratingGood,
            child: Text(
              'Importado: ${_importResult!.decksCreated} deck(s), ${_importResult!.notesImported} notas, ${_importResult!.cardsImported} cartoes e ${_importResult!.reviewsImported} revisoes.',
            ),
          ),
        ],
        if (_exportResult != null) ...<Widget>[
          const SizedBox(height: 14),
          GlassBentoCard(
            accentBorderColor: colors.accentCyan,
            child: Text(
              'Pacote gerado: ${_exportResult!.fileName} (${_exportResult!.cardsExported} cartoes exportados).',
            ),
          ),
        ],
      ],
    );
  }
}

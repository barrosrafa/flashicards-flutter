import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/glass_bento_card.dart';

/// AI & Power Tools Hub (`/tools`) providing 1-tap access to AI Ingestion,
/// Multi-Touch Image Occlusion, Hybrid Semantic Search, Anki `.apkg` Transfer,
/// Structured CSV/JSON/MD Imports, Custom Templates, and the MCP External Server.
class ToolsHubScreen extends StatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> {
  List<String> _mcpTools = const <String>[];

  @override
  void initState() {
    super.initState();
    _loadMcpTools();
  }

  Future<void> _loadMcpTools() async {
    final List<String> tools =
        await ServiceLocator.instance.mcpClient.listTools();
    if (!mounted) {
      return;
    }
    setState(() => _mcpTools = tools);
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: <Widget>[
        Text(
          'Laboratorio IA & Power Tools',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Ferramentas avancadas de criacao multimodal, busca vetorial e interoperabilidade Anki/MCP.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 18),

        _ToolBentoCard(
          icon: Icons.auto_awesome_rounded,
          badge: 'EDGE FUNCTION · ingest-document',
          title: 'Ingestao Neural por IA (PDF / YouTube / Texto)',
          subtitle:
              'Sintetiza cartoes FSRS-6 automaticamente a partir de documentos, aulas ou artigos.',
          onTap: () => context.go('/ingest'),
        ),
        const SizedBox(height: 12),
        _ToolBentoCard(
          icon: Icons.crop_free_rounded,
          badge: 'CANVAS 0..100% · create_image_occlusion_note',
          title: 'Oclusao de Imagem Multi-Toque',
          subtitle:
              'Desenhe mascaras sobre diagramas anatomicos ou mapas e gere 1 cartao por mascara.',
          onTap: () => context.go('/occlusion'),
        ),
        const SizedBox(height: 12),
        _ToolBentoCard(
          icon: Icons.manage_search_rounded,
          badge: 'PGVECTOR + RRF · semantic-search',
          title: 'Busca Semantica Hibrida',
          subtitle:
              'Pesquise por significado usando embeddings text-embedding-3-small + Full-Text Search.',
          onTap: () => context.go('/search'),
        ),
        const SizedBox(height: 12),
        _ToolBentoCard(
          icon: Icons.swap_vert_circle_rounded,
          badge: 'BUCKET anki-transfers · anki-import / anki-export',
          title: 'Importar & Exportar Anki (.apkg / .colpkg)',
          subtitle:
              'Migracao completa preservando modelos Cloze, arquivos de midia e agendamentos.',
          onTap: () => context.go('/anki'),
        ),
        const SizedBox(height: 12),
        _ToolBentoCard(
          icon: Icons.upload_file_rounded,
          badge: 'EDGE FUNCTION · import-deck',
          title: 'Importador Estruturado (CSV / TSV / JSON / MD / XML)',
          subtitle:
              'Importe planilhas e listas de estudo em lote com validacao automatica.',
          onTap: () => context.go('/import'),
        ),
        const SizedBox(height: 12),
        _ToolBentoCard(
          icon: Icons.code_rounded,
          badge: 'ANKI SYNTAX · TemplateRenderer',
          title: 'Editor de Modelos & Cloze ({{c1::...}})',
          subtitle:
              'Customize campos, blocos condicionais {{#Field}} e cartoes reversos.',
          onTap: () => context.go('/templates'),
        ),
        const SizedBox(height: 18),

        // MCP External Tools Card
        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PROTOCOLO MCP (MODEL CONTEXT PROTOCOL)',
                style: FlashiTypography.monoMetric(
                  color: colors.accentViolet,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ferramentas MCP ativas no servidor Flashi:',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _mcpTools
                    .map(
                      (String tool) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentViolet.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tool,
                          style: FlashiTypography.monoMetric(
                            color: colors.accentViolet,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolBentoCard extends StatelessWidget {
  const _ToolBentoCard({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    return GlassBentoCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentCyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.accentCyan, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  badge,
                  style: FlashiTypography.monoMetric(
                    color: colors.accentCyan,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

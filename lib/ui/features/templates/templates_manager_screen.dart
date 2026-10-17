import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/card_template.dart';
import '../../../domain/services/template_renderer.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';
import '../../core/widgets/futuristic_form_field.dart';
import '../../core/widgets/glass_bento_card.dart';

/// Custom Card Template Manager (`/templates`) with live `TemplateRenderer`
/// preview supporting `{{Field}}`, `{{#Cond}}...{{/Cond}}`, `{{cloze:Text}}`,
/// and `{{type:Field}}`.
///
/// Mirrors `src/app/templates/page.tsx` from `app-flashi`.
class TemplatesManagerScreen extends StatefulWidget {
  const TemplatesManagerScreen({super.key});

  @override
  State<TemplatesManagerScreen> createState() => _TemplatesManagerScreenState();
}

class _TemplatesManagerScreenState extends State<TemplatesManagerScreen> {
  List<CardTemplate> _templates = const <CardTemplate>[];
  final TextEditingController _nameController = TextEditingController(
    text: 'Modelo Medico Avancado',
  );
  final TextEditingController _frontController = TextEditingController(
    text: '{{cloze:Text}}\n{{#Hint}}Dica: {{Hint}}{{/Hint}}',
  );
  final TextEditingController _backController = TextEditingController(
    text: '{{FrontSide}}\n\n---\n\n{{Extra}}',
  );
  bool _isCloze = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    final ServiceLocator locator = ServiceLocator.instance;
    final List<CardTemplate> list = await locator.templateRepository
        .listTemplates(userId: locator.activeUserId);
    if (!mounted) {
      return;
    }
    setState(() => _templates = list);
  }

  Future<void> _saveCustomTemplate() async {
    if (_nameController.text.trim().isEmpty) {
      return;
    }
    final ServiceLocator locator = ServiceLocator.instance;
    await locator.templateRepository.createTemplate(
      userId: locator.activeUserId,
      name: _nameController.text,
      isCloze: _isCloze,
      fieldNames: const <String>['Text', 'Hint', 'Extra'],
      frontTemplate: _frontController.text,
      backTemplate: _backController.text,
    );
    await _loadTemplates();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modelo personalizado salvo!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final List<RenderedCard> previewCards = TemplateRenderer.renderCards(
      fields: const <String, String>{
        'Text': 'O nodo {{c1::sinoatrial::marcapasso}} inicia o impulso cardiaco.',
        'Hint': 'Localizado no atrio direito',
        'Extra': 'Frequencia intrinseca de 60 a 100 bpm.',
      },
      rules: <CardGenerationRule>[
        CardGenerationRule(
          name: 'Preview',
          frontTemplate: _frontController.text,
          backTemplate: _backController.text,
        ),
      ],
      isCloze: _isCloze,
    );

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
                'Modelos de Nota & Cloze',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Editor Card
        GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FuturisticFormField(
                label: 'Nome do Modelo',
                controller: _nameController,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Habilitar Cloze {{c1::...}}'),
                value: _isCloze,
                onChanged: (bool v) => setState(() => _isCloze = v),
              ),
              FuturisticFormField(
                label: 'Template da Frente',
                controller: _frontController,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              FuturisticFormField(
                label: 'Template do Verso',
                controller: _backController,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              CyberPrimaryButton(
                label: 'Salvar Modelo',
                icon: Icons.save_rounded,
                fullWidth: true,
                onPressed: _saveCustomTemplate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Live Preview
        if (previewCards.isNotEmpty)
          GlassBentoCard(
            accentBorderColor: colors.accentCyan.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'LIVE PREVIEW (${previewCards.first.ruleName})',
                  style: FlashiTypography.monoMetric(
                    color: colors.accentCyan,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Frente:\n${previewCards.first.frontHtml}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Divider(height: 20),
                Text(
                  'Verso:\n${previewCards.first.backHtml}',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),

        Text(
          'Modelos Disponiveis (${_templates.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ..._templates.map(
          (CardTemplate t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassBentoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Icon(
                    t.isCloze ? Icons.code_rounded : Icons.style_rounded,
                    color: colors.accentCyan,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          t.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (t.description != null)
                          Text(
                            t.description!,
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

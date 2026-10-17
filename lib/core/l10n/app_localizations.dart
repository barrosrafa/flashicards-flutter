import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controlador de internacionalização compatível com `contexts/LanguageContext.tsx`
/// e os arquivos `assets/l10n/{pt-BR,en,es}.json`.
class AppLocalizations extends ChangeNotifier {
  AppLocalizations._();

  static final AppLocalizations instance = AppLocalizations._();
  static const String _storageKey = 'flashi:locale:v1';
  static const List<String> supportedLocales = ['pt-BR', 'en', 'es'];

  String _locale = 'pt-BR';
  Map<String, dynamic> _dictionary = const {};

  String get locale => _locale;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null && supportedLocales.contains(saved)) {
        _locale = saved;
      }
    } catch (_) {}
    await _loadLocaleAssets(_locale);
  }

  Future<void> setLocale(String nextLocale) async {
    if (!supportedLocales.contains(nextLocale) || nextLocale == _locale) return;
    _locale = nextLocale;
    await _loadLocaleAssets(nextLocale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, nextLocale);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _loadLocaleAssets(String targetLocale) async {
    try {
      final rawJson =
          await rootBundle.loadString('assets/l10n/$targetLocale.json');
      _dictionary = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (_) {
      _dictionary = _fallbackPtBr;
    }
  }

  /// Traduz uma chave hierárquica (ex.: `nav.overview`, `dashboard.learningPlanTitle`).
  String t(String key, [Map<String, String>? params]) {
    final segments = key.split('.');
    dynamic current = _dictionary;
    for (final segment in segments) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        current = null;
        break;
      }
    }
    var resolved = current is String ? current : (_fallbackPtBr[key] ?? key);
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        resolved = resolved.replaceAll('{$paramKey}', paramValue);
      });
    }
    return resolved;
  }

  static const Map<String, String> _fallbackPtBr = {
    'nav.overview': 'Visão geral',
    'nav.study': 'Estudar',
    'nav.decks': 'Meus decks',
    'nav.createContent': 'Criar conteúdo',
    'nav.analytics': 'Desempenho',
    'nav.exams': 'Exames',
    'nav.search': 'Busca semântica',
    'nav.imports': 'Importar deck',
    'nav.tools': 'Ferramentas',
    'nav.templates': 'Modelos de cartão',
    'nav.aiIngest': 'Ingestão por IA',
    'nav.anki': 'Anki (.apkg)',
    'nav.occlusion': 'Oclusão de imagem',
    'nav.socratic': 'Remediação socrática',
    'nav.leaderboard': 'Ranking',
    'nav.mcp': 'Console MCP',
    'nav.profile': 'Perfil',
    'nav.learningGoal': 'Plano de estudo',
    'nav.more': 'Mais',
    'topbar.eyebrow': 'FLASHI SPATIAL AURORA',
    'dashboard.learningPlanTitle': 'Plano de aprendizagem',
    'dashboard.learningPlanEmpty':
        'Defina um objetivo e ritmo semanal para personalizar sua fila.',
    'dashboard.learningPlanEdit': 'Ajustar plano',
    'dashboard.learningPlanSet': 'Definir plano',
    'dashboard.estimatedTime': 'Tempo estimado para zerar a fila',
    'dashboard.estimateUnavailable': 'Estude alguns cartões para calibrar o tempo estimado.',
    'onboarding.goals.exam': 'Prova ou certificação',
    'onboarding.goals.competition': 'Concurso público ou residência',
    'onboarding.goals.language': 'Aprendizado de idiomas',
    'onboarding.goals.university': 'Faculdade ou pós-graduação',
    'onboarding.goals.other': 'Estudo contínuo',
  };
}

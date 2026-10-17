import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controlador de internacionalização compatível com MaterialApp.router,
/// contexts/LanguageContext.tsx e os arquivos assets/l10n/{pt-BR,en,es}.json.
class AppLocalizations extends ChangeNotifier {
  AppLocalizations._();

  static final AppLocalizations instance = AppLocalizations._();
  static const String storageKey = 'flashi:locale:v1';

  static const List<String> supportedLocaleCodes = <String>['pt-BR', 'en', 'es'];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt', 'BR'),
    Locale('en'),
    Locale('es'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        instance;
  }

  String _locale = 'pt-BR';
  Map<String, dynamic> _dictionary = const <String, dynamic>{};

  String get locale => _locale;

  Locale get currentLocaleObject {
    if (_locale.startsWith('pt')) return const Locale('pt', 'BR');
    if (_locale.startsWith('es')) return const Locale('es');
    return const Locale('en');
  }

  static String normalizeLocaleCode(String raw) {
    final String lower = raw.trim().toLowerCase().replaceAll('_', '-');
    if (lower.startsWith('pt')) return 'pt-BR';
    if (lower.startsWith('es')) return 'es';
    if (lower.startsWith('en')) return 'en';
    return 'pt-BR';
  }

  Future<void> initialize() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved =
          prefs.getString(storageKey) ?? prefs.getString('flashi.locale');
      if (saved != null && saved.isNotEmpty) {
        _locale = normalizeLocaleCode(saved);
      }
    } catch (_) {}
    await _loadLocaleAssets(_locale);
  }

  Future<void> setLocale(String nextLocale) async {
    final String normalized = normalizeLocaleCode(nextLocale);
    if (!supportedLocaleCodes.contains(normalized)) return;
    _locale = normalized;
    await _loadLocaleAssets(normalized);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, normalized);
      await prefs.setString('flashi.locale', normalized);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _loadLocaleAssets(String targetLocale) async {
    try {
      final String rawJson =
          await rootBundle.loadString('assets/l10n/$targetLocale.json');
      _dictionary = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (_) {
      _dictionary = _fallbackPtBr;
    }
  }

  /// Traduz uma chave hierárquica (ex.: `nav.overview`, `dashboard.learningPlanTitle`).
  String t(String key, [Map<String, String>? params]) {
    final List<String> segments = key.split('.');
    dynamic current = _dictionary;
    for (final String segment in segments) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        current = null;
        break;
      }
    }
    String resolved =
        current is String ? current : (_fallbackPtBr[key] ?? key);
    if (params != null) {
      params.forEach((String paramKey, String paramValue) {
        resolved = resolved.replaceAll('{$paramKey}', paramValue);
      });
    }
    return resolved;
  }

  /// Traduz uma chave hierárquica com suporte a valor padrão fallback.
  String tr(
    String key, {
    String? fallback,
    Map<String, String>? params,
  }) {
    final String translated = t(key, params);
    if (translated == key && fallback != null) {
      return fallback;
    }
    return translated;
  }

  static const Map<String, String> _fallbackPtBr = <String, String>{
    'nav.dashboard': 'Dashboard',
    'nav.overview': 'Visão geral',
    'nav.study': 'Estudar',
    'nav.decks': 'Baralhos',
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
    'dashboard.estimateUnavailable':
        'Estude alguns cartões para calibrar o tempo estimado.',
    'onboarding.goals.exam': 'Prova ou certificação',
    'onboarding.goals.competition': 'Concurso público ou residência',
    'onboarding.goals.language': 'Aprendizado de idiomas',
    'onboarding.goals.university': 'Faculdade ou pós-graduação',
    'onboarding.goals.other': 'Estudo contínuo',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['pt', 'en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final String code = locale.languageCode == 'pt'
        ? 'pt-BR'
        : locale.languageCode;
    await AppLocalizations.instance.setLocale(code);
    return AppLocalizations.instance;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

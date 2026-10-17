import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reactive controller managing Dark OLED (default) vs. Light theme mode and
/// active locale (`pt-BR`, `en`, `es`).
class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeMode initialThemeMode = ThemeMode.dark,
    Locale initialLocale = const Locale('pt', 'BR'),
  })  : _themeMode = initialThemeMode,
        _locale = initialLocale;

  ThemeMode _themeMode;
  Locale _locale;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isDarkMode => _themeMode != ThemeMode.light;

  static const String _prefThemeKey = 'flashi.theme_mode';
  static const String _prefLocaleKey = 'flashi.locale';

  Future<void> loadSavedPreferences() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedTheme = prefs.getString(_prefThemeKey);
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }

      final String? savedLocale = prefs.getString(_prefLocaleKey);
      if (savedLocale == 'en') {
        _locale = const Locale('en');
      } else if (savedLocale == 'es') {
        _locale = const Locale('es');
      } else {
        _locale = const Locale('pt', 'BR');
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, mode.name);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<void> setLocaleCode(String code) async {
    if (code == 'en') {
      _locale = const Locale('en');
    } else if (code == 'es') {
      _locale = const Locale('es');
    } else {
      _locale = const Locale('pt', 'BR');
    }
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLocaleKey, code);
    } catch (_) {}
  }
}

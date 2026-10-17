import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'ui/core/theme/flashi_theme.dart';

/// Root `MaterialApp.router` widget for Flashi.
class FlashiApp extends StatefulWidget {
  const FlashiApp({super.key});

  @override
  State<FlashiApp> createState() => _FlashiAppState();
}

class _FlashiAppState extends State<FlashiApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();
  }

  @override
  Widget build(BuildContext context) {
    final ServiceLocator locator = ServiceLocator.instance;

    return ListenableBuilder(
      listenable: locator.themeController,
      builder: (BuildContext context, _) {
        return MaterialApp.router(
          title: 'Flashi',
          debugShowCheckedModeBanner: false,
          theme: FlashiTheme.lightTheme,
          darkTheme: FlashiTheme.darkTheme,
          themeMode: locator.themeController.themeMode,
          locale: locator.themeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        );
      },
    );
  }
}

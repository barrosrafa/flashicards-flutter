import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/observability/observability_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ServiceLocator locator = ServiceLocator.instance;
  await locator.supabaseProvider.initialize();
  await locator.themeController.loadSavedPreferences();
  await locator.authRepository.bootstrapSession();

  await ObservabilityService.instance.runGuarded(() async {
    runApp(const FlashiApp());
  });
}

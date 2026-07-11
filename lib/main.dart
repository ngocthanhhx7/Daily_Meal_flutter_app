import 'package:daily_meal_flutter_app/app/app.dart';
import 'package:daily_meal_flutter_app/app/config/app_config.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store_provider.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final sessionStore = await createSessionStore();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sessionStoreProvider.overrideWithValue(sessionStore),
      ],
      child: const DailyMealApp(),
    ),
  );
}

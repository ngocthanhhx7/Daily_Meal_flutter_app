import 'package:daily_meal_flutter_app/app/app.dart';
import 'package:daily_meal_flutter_app/app/config/app_config.dart';
import 'package:daily_meal_flutter_app/core/storage/key_value_storage.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements KeyValueStorage {
  @override
  Future<void> delete(String key) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
}

void main() {
  testWidgets('boots the Daily Meal application', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromMap(const {
              'API_BASE_URL': 'https://api.dailymeal.site',
              'FACEBOOK_APP_ID': 'facebook-id',
              'GOOGLE_WEB_CLIENT_ID': 'google-id',
            }),
          ),
          sessionStoreProvider.overrideWithValue(
            KeyValueSessionStore(_MemoryStorage(), keyPrefix: 'widget.test'),
          ),
        ],
        child: const DailyMealApp(),
      ),
    );

    expect(find.bySemanticsLabel('Daily Meal application'), findsOneWidget);
  });
}

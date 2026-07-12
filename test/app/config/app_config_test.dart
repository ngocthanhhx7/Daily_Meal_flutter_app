import 'package:daily_meal_flutter_app/app/config/app_config.dart';
import 'package:daily_meal_flutter_app/app/config/config_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ships safe production defaults for builds without dart defines', () {
    final config = AppConfig.fromEnvironment();

    expect(config.apiBaseUrl.toString(), 'https://api.dailymeal.site');
    expect(config.facebookAppId, '3483710358450589');
    expect(
      config.googleWebClientId,
      '20654020356-nsqam5ladrg7j5v6agefq8pucnrcqtn8.apps.googleusercontent.com',
    );
  });

  const validValues = {
    'API_BASE_URL': 'https://api.dailymeal.site/',
    'FACEBOOK_APP_ID': '3483710358450589',
    'GOOGLE_WEB_CLIENT_ID': '20654020356-example.apps.googleusercontent.com',
  };

  test('accepts production values and normalizes the API trailing slash', () {
    final config = AppConfig.fromMap(validValues);

    expect(config.apiBaseUrl.toString(), 'https://api.dailymeal.site');
    expect(config.facebookAppId, '3483710358450589');
    expect(
      config.googleWebClientId,
      '20654020356-example.apps.googleusercontent.com',
    );
  });

  test('rejects a missing API base URL', () {
    expect(
      () => AppConfig.fromMap({...validValues, 'API_BASE_URL': ''}),
      throwsA(
        isA<ConfigException>().having(
          (error) => error.key,
          'key',
          'API_BASE_URL',
        ),
      ),
    );
  });

  test('rejects a malformed API base URL', () {
    expect(
      () => AppConfig.fromMap({...validValues, 'API_BASE_URL': 'not-a-url'}),
      throwsA(isA<ConfigException>()),
    );
  });

  test('requires HTTPS for non-local API hosts', () {
    expect(
      () => AppConfig.fromMap({
        ...validValues,
        'API_BASE_URL': 'http://api.dailymeal.site',
      }),
      throwsA(isA<ConfigException>()),
    );
  });

  test('allows HTTP for Android emulator and loopback development hosts', () {
    for (final url in [
      'http://10.0.2.2:4000',
      'http://localhost:4000',
      'http://127.0.0.1:4000',
    ]) {
      expect(
        AppConfig.fromMap({
          ...validValues,
          'API_BASE_URL': url,
        }).apiBaseUrl.host,
        isNotEmpty,
      );
    }
  });
}

import 'package:daily_meal_flutter_app/core/analytics/analytics_event.dart';
import 'package:daily_meal_flutter_app/core/analytics/analytics_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sanitizer = AnalyticsSanitizer();

  test('preserves allow-listed telemetry fields', () {
    final result = sanitizer.sanitize(
      const AnalyticsEvent(
        name: 'screen_view',
        properties: {
          'screen': 'Home',
          'referrer': 'Login',
          'durationMs': 420,
          'status': 'success',
        },
      ),
    );

    expect(result.properties, {
      'screen': 'Home',
      'referrer': 'Login',
      'durationMs': 420,
      'status': 'success',
    });
  });

  test('removes sensitive and unknown fields recursively', () {
    final result = sanitizer.sanitize(
      const AnalyticsEvent(
        name: 'api_request',
        properties: {
          'screen': 'Login',
          'password': 'secret',
          'otp': '123456',
          'token': 'jwt',
          'authorization': 'Bearer jwt',
          'messageBody': 'private chat',
          'unknown': 'drop me',
          'context': {'token': 'nested-jwt', 'status': 'failed'},
        },
      ),
    );

    expect(result.toString(), isNot(contains('secret')));
    expect(result.toString(), isNot(contains('nested-jwt')));
    expect(result.properties, {
      'screen': 'Login',
      'context': {'status': 'failed'},
    });
  });

  test('rejects unsafe event names', () {
    expect(
      () =>
          sanitizer.sanitize(const AnalyticsEvent(name: 'password_submitted')),
      throwsArgumentError,
    );
  });
}

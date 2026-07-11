import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/onboarding/data/onboarding_repository.dart';
import 'package:daily_meal_flutter_app/features/onboarding/domain/preference_options.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({
        'preferences': {
          'interests': options.data['interests'],
          'eatingStyles': options.data['eatingStyles'],
          'completedOnboarding': true,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('preserves the exact production preference options', () {
    expect(interestOptions.first, 'Thích chụp ảnh');
    expect(interestOptions, hasLength(5));
    expect(eatingStyleOptions, contains('Chế độ keto'));
    expect(eatingStyleOptions, hasLength(5));
  });

  test('saves preferences with the exact PATCH contract', () async {
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
      ..httpClientAdapter = adapter;
    final repository = OnboardingRepository(dio);

    final preferences = await repository.savePreferences(
      interests: const ['Thích ăn uống'],
      eatingStyles: const ['Chế độ keto'],
    );

    expect(adapter.request?.method, 'PATCH');
    expect(adapter.request?.path, '/api/onboarding/preferences');
    expect(preferences.completedOnboarding, isTrue);
  });
}

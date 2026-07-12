import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:dio/dio.dart';

class OnboardingRepository {
  OnboardingRepository(this._dio);
  final Dio _dio;

  Future<UserPreferences> savePreferences({
    required List<String> interests,
    required List<String> eatingStyles,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/onboarding/preferences',
      data: {'interests': interests, 'eatingStyles': eatingStyles},
    );
    final data = response.data;
    if (data == null || data['preferences'] is! Map) {
      throw const FormatException('Missing onboarding preferences');
    }
    return UserPreferences.fromJson(
      (data['preferences'] as Map).cast<String, dynamic>(),
    );
  }
}

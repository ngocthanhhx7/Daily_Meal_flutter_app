import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/premium/domain/premium_models.dart';
import 'package:dio/dio.dart';

class PremiumApi {
  PremiumApi(this._dio);
  final Dio _dio;
  Future<List<PremiumPlan>> plans() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/payments/premium/plans',
    );
    final raw = response.data?['plans'];
    if (raw is! List) {
      throw const FormatException('Invalid Premium plans response');
    }
    return raw
        .whereType<Map>()
        .map((item) => PremiumPlan.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<PayosPayment> createPayment(PremiumPlanId planId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/payments/payos/create',
      data: {'planId': planId.wireValue},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Invalid PayOS response');
    }
    return PayosPayment.fromJson(data);
  }

  Future<PayosPayment> payment(int orderCode) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/payments/payos/$orderCode',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Invalid PayOS status response');
    }
    return PayosPayment.fromJson(data);
  }

  Future<AppUser> claimTrial() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/users/me/premium-trial',
    );
    final raw = response.data?['user'];
    if (raw is! Map) {
      throw const FormatException('Invalid Premium trial response');
    }
    return AppUser.fromJson(raw.cast<String, dynamic>());
  }
}

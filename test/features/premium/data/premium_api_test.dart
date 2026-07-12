import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/premium/data/premium_api.dart';
import 'package:daily_meal_flutter_app/features/premium/domain/premium_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> payment(String status) => {
  'id': 'p1',
  'planId': 'premium_quarter',
  'orderCode': 123,
  'amount': 99000,
  'currency': 'VND',
  'status': status,
  'checkoutUrl': 'https://pay.payos.vn/web/p1',
};

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = switch ((options.method, options.path)) {
      ('GET', '/api/payments/premium/plans') => {
        'plans': [
          {
            'id': 'premium_quarter',
            'name': 'Gói 3 tháng',
            'displayPrice': '99k/3 tháng',
            'amount': 99000,
            'durationMonths': 3,
          },
        ],
      },
      ('POST', '/api/payments/payos/create') => payment('PENDING'),
      ('GET', '/api/payments/payos/123') => payment('PAID'),
      ('POST', '/api/users/me/premium-trial') => {
        'user': {
          'id': 'u1',
          'displayName': 'User',
          'isPremium': true,
          'premiumTrialUsed': true,
          'preferences': {'completedOnboarding': true},
          'counts': {},
        },
      },
      _ => throw StateError('${options.method} ${options.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
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
  test('uses exact plans, PayOS status and trial contracts', () async {
    final adapter = _Adapter();
    final api = PremiumApi(
      Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
        ..httpClientAdapter = adapter,
    );
    expect((await api.plans()).single.amount, 99000);
    expect(
      (await api.createPayment(PremiumPlanId.quarter)).status,
      PaymentStatus.pending,
    );
    expect((await api.payment(123)).status, PaymentStatus.paid);
    expect((await api.claimTrial()).premiumTrialUsed, isTrue);
    expect(
      adapter.requests
          .singleWhere((item) => item.path == '/api/payments/payos/create')
          .data,
      {'planId': 'premium_quarter'},
    );
  });
}

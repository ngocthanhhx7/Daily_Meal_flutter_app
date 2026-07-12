import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/admin/data/admin_api.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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
      ('GET', '/api/admin/dashboard') => {
        'range': {
          'start': '2026-07-05T00:00:00.000Z',
          'end': '2026-07-12T00:00:00.000Z',
        },
        'rangePreset': '7d',
        'totalsAllTime': {
          'users': 120,
          'posts': 80,
          'meals': 40,
          'comments': 22,
          'likes': 300,
          'saves': 70,
          'payments': 12,
          'revenue': 990000,
          'premiumUsers': 10,
          'openReports': 3,
          'hiddenPosts': 2,
        },
        'totalsInRange': {'users': 7, 'posts': 11, 'revenue': 99000},
        'today': {'users': 2, 'posts': 3, 'interactions': 9},
        'charts': {
          'daily': [
            {
              'date': '2026-07-11',
              'users': 2,
              'posts': 3,
              'interactions': 9,
              'payments': 1,
              'revenue': 99000,
              'reports': 1,
              'apiErrors': 0,
            },
          ],
        },
        'breakdowns': {
          'usersByPremium': [
            {'_id': 'premium', 'count': 10},
          ],
          'postsByVisibility': [],
          'postsByModeration': [],
          'paymentsByStatus': [],
          'reportsByStatus': [],
        },
        'recent': {'reports': [], 'posts': [], 'payments': [], 'audit': []},
      },
      ('GET', '/api/admin/users') => {
        'users': [
          {
            'id': 'u1',
            'displayName': 'An',
            'email': 'an@example.com',
            'isPremium': false,
            'createdAt': '2026-01-01T00:00:00Z',
          },
        ],
        'pagination': {'page': 2, 'limit': 20, 'total': 25, 'pages': 2},
      },
      ('PATCH', '/api/admin/users/u1/premium') => {
        'user': {'id': 'u1', 'displayName': 'An', 'isPremium': true},
      },
      ('GET', '/api/admin/users/insights') => {
        'summary': {'activeUsers': 10},
      },
      ('GET', '/api/admin/users/u1') => {
        'user': {
          'id': 'u1',
          'displayName': 'An',
          'email': 'an@example.com',
          'stats': {'posts': 2},
        },
      },
      ('GET', '/api/admin/posts') => {
        'posts': [
          {
            'id': 'p1',
            'caption': 'Bữa sáng',
            'moderationStatus': 'visible',
            'visibility': 'public',
            'stats': {},
          },
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
      },
      ('PATCH', '/api/admin/posts/p1/moderation') => {
        'post': {
          'id': 'p1',
          'caption': 'Bữa sáng',
          'moderationStatus': 'hidden',
          'visibility': 'public',
          'stats': {},
        },
      },
      ('GET', '/api/admin/posts/insights') => {
        'summary': {'posts': 1},
      },
      ('GET', '/api/admin/reports') => {
        'reports': [
          {'id': 'r1', 'note': 'spam', 'status': 'open'},
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
      },
      ('PATCH', '/api/admin/reports/r1') => {
        'report': {
          'id': 'r1',
          'note': 'spam',
          'status': 'resolved',
          'adminNote': 'done',
        },
      },
      ('GET', '/api/admin/payments') => {
        'payments': [
          {
            'id': 'pay1',
            'planId': 'premium_month',
            'orderCode': 123,
            'amount': 39000,
            'currency': 'VND',
            'status': 'PAID',
          },
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
      },
      ('GET', '/api/admin/analytics/summary') => {
        'summary': {
          'activeUsers': {'dau': 8},
        },
      },
      ('GET', '/api/admin/analytics/24h') => {
        'summary': {'activeUsers': 8},
        'hourly': [
          {'hour': 9, 'label': '09:00', 'events': 12},
        ],
      },
      ('GET', '/api/admin/analytics/heatmap') => {
        'metric': 'events',
        'cells': [
          {'day': '2026-07-12', 'weekday': 'CN', 'hour': 9, 'value': 12},
        ],
      },
      ('POST', '/api/admin/reports/ai') => {
        'report': {
          'title': 'Báo cáo tuần',
          'executiveSummary': ['Tăng trưởng'],
          'sections': [],
          'priorityActions': ['Theo dõi'],
        },
        'generatedAt': '2026-07-12T00:00:00Z',
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
  test('loads dashboard using exact admin range contract', () async {
    final adapter = _Adapter();
    final api = AdminApi(
      Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
        ..httpClientAdapter = adapter,
    );

    final dashboard = await api.dashboard(AdminRange.sevenDays);

    expect(dashboard.allTime.users, 120);
    expect(dashboard.inRange.revenue, 99000);
    expect(dashboard.daily.single.interactions, 9);
    expect(dashboard.breakdowns.usersByPremium.single.label, 'premium');
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/api/admin/dashboard');
    expect(adapter.requests.single.queryParameters, {'range': '7d'});
  });

  test('uses exact list filters and moderation mutation contracts', () async {
    final adapter = _Adapter();
    final api = AdminApi(Dio()..httpClientAdapter = adapter);
    expect((await api.users(query: 'an', page: 2)).items.single.name, 'An');
    expect(
      (await api.setPremium('u1', true, note: 'approved')).isPremium,
      isTrue,
    );
    expect((await api.posts(moderationStatus: 'review')).items.single.id, 'p1');
    expect(
      (await api.moderatePost('p1', 'hidden', reason: 'spam')).moderationStatus,
      'hidden',
    );
    expect((await api.reports(status: 'open')).items.single.note, 'spam');
    expect(
      (await api.updateReport('r1', 'resolved', adminNote: 'done')).status,
      'resolved',
    );
    expect((await api.payments(query: '123')).items.single.amount, 39000);
    expect(adapter.requests[0].queryParameters, {
      'q': 'an',
      'page': 2,
      'limit': 20,
    });
    expect(adapter.requests[1].data, {'isPremium': true, 'note': 'approved'});
    expect(adapter.requests[2].queryParameters['moderationStatus'], 'review');
    expect(adapter.requests[3].data, {
      'moderationStatus': 'hidden',
      'reason': 'spam',
    });
    expect(adapter.requests[4].queryParameters['status'], 'open');
    expect(adapter.requests[5].data, {
      'status': 'resolved',
      'adminNote': 'done',
    });
    expect(adapter.requests[6].queryParameters, {
      'q': '123',
      'page': 1,
      'limit': 20,
    });
  });

  test(
    'uses exact analytics timezone, heatmap and AI report contracts',
    () async {
      final adapter = _Adapter();
      final api = AdminApi(Dio()..httpClientAdapter = adapter);
      expect(
        (await api.analyticsSummary(AdminRange.sevenDays))['summary'],
        isNotNull,
      );
      expect((await api.analytics24h()).hourly.single.events, 12);
      expect((await api.heatmap()).cells.single.hour, 9);
      expect(
        (await api.generateAiReport(AdminRange.thirtyDays)).title,
        'Báo cáo tuần',
      );
      expect(adapter.requests[0].queryParameters, {'range': '7d'});
      expect(adapter.requests[1].queryParameters, {
        'preset': 'last24h',
        'timezone': 'Asia/Ho_Chi_Minh',
      });
      expect(adapter.requests[2].queryParameters, {
        'preset': '7d',
        'timezone': 'Asia/Ho_Chi_Minh',
        'metric': 'events',
      });
      expect(adapter.requests[3].data, {'range': '30d'});
    },
  );
  test('loads exact user detail and user/post insights contracts', () async {
    final adapter = _Adapter();
    final api = AdminApi(Dio()..httpClientAdapter = adapter);
    expect(
      (await api.userInsights(AdminRange.thirtyDays))['summary'],
      isNotNull,
    );
    expect((await api.userDetail('u1'))['user'], isNotNull);
    expect(
      (await api.postInsights(moderationStatus: 'review'))['summary'],
      isNotNull,
    );
    expect(adapter.requests[0].queryParameters, {'range': '30d'});
    expect(adapter.requests[1].path, '/api/admin/users/u1');
    expect(adapter.requests[2].queryParameters, {
      'range': '30d',
      'moderationStatus': 'review',
    });
  });
}

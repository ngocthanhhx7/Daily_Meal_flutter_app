import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/notifications/data/notifications_api.dart';
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
    final data = options.path == '/api/users/web-push/vapid-public-key'
        ? {'publicKey': 'vapid-key'}
        : options.method == 'GET'
        ? {
            'notifications': [
              {
                '_id': 'n1',
                'type': 'follow',
                'sender': {'_id': 'u1', 'displayName': 'Bếp Bạn'},
                'body': 'đã theo dõi bạn',
                'read': false,
                'createdAt': '2026-07-12T01:00:00Z',
              },
            ],
          }
        : {'success': true};
    return ResponseBody.fromString(
      jsonEncode(data),
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
  test('decodes list and uses exact notification mutation endpoints', () async {
    final adapter = _Adapter();
    final api = NotificationsApi(
      Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
        ..httpClientAdapter = adapter,
    );
    expect((await api.load()).single.sender?.id, 'u1');
    await api.markRead('n1');
    await api.markAllRead();
    await api.delete('n1');
    await api.deleteAll();
    expect(await api.webPushPublicKey(), 'vapid-key');
    await api.registerWebPush({
      'endpoint': 'https://push.test',
      'keys': {'p256dh': 'p', 'auth': 'a'},
    });
    await api.unregisterWebPush('https://push.test');
    expect(
      adapter.requests.map((item) => '${item.method} ${item.path}'),
      containsAll([
        'PATCH /api/notifications/n1/read',
        'PATCH /api/notifications/read-all',
        'DELETE /api/notifications/n1',
        'DELETE /api/notifications',
        'GET /api/users/web-push/vapid-public-key',
        'POST /api/users/web-push-subscription',
        'DELETE /api/users/web-push-subscription',
      ]),
    );
  });
}

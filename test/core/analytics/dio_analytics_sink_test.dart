import 'dart:convert';
import 'dart:typed_data';
import 'package:daily_meal_flutter_app/core/analytics/analytics_event.dart';
import 'package:daily_meal_flutter_app/core/analytics/dio_analytics_sink.dart';
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
    return ResponseBody.fromString(
      jsonEncode({'accepted': 1}),
      202,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('sends the exact production ingest envelope', () async {
    final adapter = _Adapter();
    final sink = DioAnalyticsSink(
      Dio()..httpClientAdapter = adapter,
      sessionId: 'session-1',
    );
    await sink.send([
      const AnalyticsEvent(name: 'app_open', properties: {'screen': 'home'}),
    ]);
    expect(adapter.requests.single.path, '/api/ingest/events');
    final event =
        (adapter.requests.single.data['events'] as List).single as Map;
    expect(event['name'], 'app_open');
    expect(event['sessionId'], 'session-1');
    expect(event['source'], 'client');
    expect(event['screen'], 'home');
  });
}

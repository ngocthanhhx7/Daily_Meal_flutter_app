import 'package:daily_meal_flutter_app/core/analytics/analytics_client.dart';
import 'package:daily_meal_flutter_app/core/analytics/analytics_event.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioAnalyticsSink implements AnalyticsSink {
  DioAnalyticsSink(Dio dio, {String? sessionId})
    : _dio = dio,
      sessionId =
          sessionId ??
          '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(dio)}';
  final Dio _dio;
  final String sessionId;

  @override
  Future<void> send(List<AnalyticsEvent> events) async {
    for (var offset = 0; offset < events.length; offset += 100) {
      final end = (offset + 100).clamp(0, events.length);
      await _dio.post<void>(
        '/api/ingest/events',
        data: {
          'events': [
            for (final event in events.sublist(offset, end))
              {
                'name': event.name,
                'occurredAt': DateTime.now().toUtc().toIso8601String(),
                'sessionId': sessionId,
                'source': 'client',
                'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
                'screen': event.properties['screen'],
                'properties': event.properties,
              },
          ],
        },
      );
    }
  }
}

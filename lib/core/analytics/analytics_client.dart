import 'package:daily_meal_flutter_app/core/analytics/analytics_event.dart';
import 'package:daily_meal_flutter_app/core/analytics/analytics_sanitizer.dart';

abstract interface class AnalyticsSink {
  Future<void> send(List<AnalyticsEvent> events);
}

class AnalyticsClient {
  AnalyticsClient({required AnalyticsSink sink, AnalyticsSanitizer? sanitizer})
    : _sink = sink,
      _sanitizer = sanitizer ?? AnalyticsSanitizer();

  final AnalyticsSink _sink;
  final AnalyticsSanitizer _sanitizer;
  final List<AnalyticsEvent> _queue = [];
  Future<void>? _flushInFlight;

  void track(AnalyticsEvent event) {
    _queue.add(_sanitizer.sanitize(event));
  }

  Future<void> flush() {
    final current = _flushInFlight;
    if (current != null) return current;
    final future = _flush();
    _flushInFlight = future;
    return future.whenComplete(() => _flushInFlight = null);
  }

  Future<void> _flush() async {
    if (_queue.isEmpty) return;
    final batch = List<AnalyticsEvent>.unmodifiable(_queue);
    await _sink.send(batch);
    _queue.removeRange(0, batch.length);
  }
}

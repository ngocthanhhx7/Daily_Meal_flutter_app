import 'dart:async';
import 'package:daily_meal_flutter_app/core/analytics/analytics_client.dart';
import 'package:daily_meal_flutter_app/core/analytics/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sink implements AnalyticsSink {
  final calls = <List<AnalyticsEvent>>[];
  final gate = Completer<void>();
  bool fail = false;
  @override
  Future<void> send(List<AnalyticsEvent> events) async {
    calls.add(events);
    await gate.future;
    if (fail) throw StateError('offline');
  }
}

void main() {
  test('coalesces concurrent flushes without duplicate delivery', () async {
    final sink = _Sink();
    final client = AnalyticsClient(sink: sink)
      ..track(const AnalyticsEvent(name: 'app_open'));
    final first = client.flush();
    final second = client.flush();
    expect(sink.calls, hasLength(1));
    sink.gate.complete();
    await Future.wait([first, second]);
    await client.flush();
    expect(sink.calls, hasLength(1));
  });

  test('retains queued events when transport is offline', () async {
    final sink = _Sink()..fail = true;
    final client = AnalyticsClient(sink: sink)
      ..track(const AnalyticsEvent(name: 'app_open'));
    final flush = client.flush();
    sink.gate.complete();
    await expectLater(flush, throwsStateError);
    sink.fail = false;
    await client.flush();
    expect(sink.calls, hasLength(2));
  });
}

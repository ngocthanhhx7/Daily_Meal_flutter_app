import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses bounded exponential Socket.IO reconnect options', () {
    final options = buildRealtimeSocketOptions('jwt-test');

    expect(options['transports'], ['websocket']);
    expect(options['auth'], {'token': 'jwt-test'});
    expect(options['autoConnect'], isFalse);
    expect(options['forceNew'], isTrue);
    expect(options['reconnection'], isTrue);
    expect(options['reconnectionAttempts'], 6);
    expect(options['reconnectionDelay'], 1000);
    expect(options['reconnectionDelayMax'], 10000);
    expect(options['randomizationFactor'], 0.5);
  });
}

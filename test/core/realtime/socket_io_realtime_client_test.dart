import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sessions implements SessionStore {
  @override
  Future<Session?> read(SessionKind kind) async =>
      const Session.user(token: 'jwt-test', subjectId: 'user-1');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Socket implements RealtimeSocket {
  final listeners = <String, void Function(Object?)>{};
  void Function(Object?)? connectError;
  void Function()? connected;
  var connectCalls = 0;
  var disposed = false;

  @override
  void on(String event, void Function(Object?) handler) =>
      listeners[event] = handler;

  @override
  void onConnectError(void Function(Object?) handler) => connectError = handler;

  @override
  void onConnect(void Function() handler) => connected = handler;

  @override
  void connect() => connectCalls++;

  @override
  void emit(String event, Object? data) {}

  @override
  void dispose() => disposed = true;

  void trigger(String event, Object? data) => listeners[event]!(data);

  void triggerConnect() => connected!();
}

void main() {
  test('treats auth errors as terminal and disposes the socket', () async {
    final socket = _Socket();
    final client = SocketIoRealtimeClient(
      baseUrl: Uri.parse('https://api.dailymeal.site'),
      sessions: _Sessions(),
      socketFactory: (origin, options) => socket,
    );
    final errors = <String>[];
    final subscription = client.errors.listen(errors.add);

    await client.connect();
    socket.trigger('auth:error', {'message': 'Invalid session'});
    await Future<void>.delayed(Duration.zero);

    expect(socket.connectCalls, 1);
    expect(socket.disposed, isTrue);
    expect(errors, ['Invalid session']);

    await subscription.cancel();
    client.dispose();
  });

  test('emits recovery only after a connection has reconnected', () async {
    final socket = _Socket();
    final client = SocketIoRealtimeClient(
      baseUrl: Uri.parse('https://api.dailymeal.site'),
      sessions: _Sessions(),
      socketFactory: (origin, options) => socket,
    );
    var recoveries = 0;
    final subscription = client.reconnects.listen((_) => recoveries++);

    await client.connect();
    socket.triggerConnect();
    expect(recoveries, 0);

    socket.triggerConnect();
    await Future<void>.delayed(Duration.zero);
    expect(recoveries, 1);

    await subscription.cancel();
    client.dispose();
  });
}

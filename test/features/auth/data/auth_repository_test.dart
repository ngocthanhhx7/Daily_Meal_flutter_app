import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/core/storage/key_value_storage.dart';
import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_api.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements KeyValueStorage {
  final values = <String, String>{};
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _AuthAdapter implements HttpClientAdapter {
  int statusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.path == '/api/admin/login'
        ? {
            'token': 'admin-token',
            'admin': {'email': 'admin@dailymeal.site', 'displayName': 'Admin'},
          }
        : {
            'token': 'user-token',
            'user': {
              'id': 'user-1',
              'email': 'meal@example.com',
              'displayName': 'Meal',
              'isPremium': false,
              'preferences': {
                'interests': <String>[],
                'eatingStyles': <String>[],
                'completedOnboarding': false,
              },
            },
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _AuthAdapter adapter;
  late SessionStore sessions;
  late AuthRepository repository;

  setUp(() {
    adapter = _AuthAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
      ..httpClientAdapter = adapter;
    sessions = KeyValueSessionStore(
      _MemoryStorage(),
      keyPrefix: 'test.session',
    );
    repository = AuthRepository(AuthApi(dio), sessions);
  });

  test('successful user login persists user and removes admin', () async {
    await sessions.save(
      const Session.admin(token: 'old-admin', subjectId: 'admin'),
    );

    final user = await repository.login(
      email: 'meal@example.com',
      password: '123456',
    );

    expect(user.id, 'user-1');
    expect((await sessions.read(SessionKind.user))?.token, 'user-token');
    expect(await sessions.read(SessionKind.admin), isNull);
  });

  test('successful admin login persists admin and removes user', () async {
    await sessions.save(
      const Session.user(token: 'old-user', subjectId: 'user-1'),
    );

    await repository.adminLogin(
      email: 'admin@dailymeal.site',
      password: 'secret',
    );

    expect((await sessions.read(SessionKind.admin))?.token, 'admin-token');
    expect(await sessions.read(SessionKind.user), isNull);
  });

  test('failed authentication does not persist a session', () async {
    adapter.statusCode = 401;

    await expectLater(
      repository.login(email: 'meal@example.com', password: 'bad'),
      throwsA(isA<DioException>()),
    );

    expect(await sessions.read(SessionKind.user), isNull);
    expect(await sessions.read(SessionKind.admin), isNull);
  });

  test('logout clears both session kinds', () async {
    await sessions.save(const Session.user(token: 'user', subjectId: 'user-1'));
    await sessions.save(
      const Session.admin(token: 'admin', subjectId: 'admin'),
    );

    await repository.logout();

    expect(await sessions.read(SessionKind.user), isNull);
    expect(await sessions.read(SessionKind.admin), isNull);
  });
}

import 'package:daily_meal_flutter_app/core/storage/key_value_storage.dart';
import 'package:daily_meal_flutter_app/core/storage/secure_session_store.dart';
import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:daily_meal_flutter_app/core/storage/web_session_store.dart';
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

void sessionStoreContract(
  String name,
  SessionStore Function(KeyValueStorage storage) create,
) {
  group(name, () {
    late SessionStore store;

    setUp(() => store = create(_MemoryStorage()));

    test('saves and reads user and admin sessions independently', () async {
      const user = Session.user(token: 'user-jwt', subjectId: 'user-1');
      const admin = Session.admin(token: 'admin-jwt', subjectId: 'admin-1');

      await store.save(user);
      await store.save(admin);

      expect(await store.read(SessionKind.user), user);
      expect(await store.read(SessionKind.admin), admin);
    });

    test('replaces a session of the same kind', () async {
      await store.save(const Session.user(token: 'old', subjectId: 'user-1'));
      await store.save(const Session.user(token: 'new', subjectId: 'user-1'));

      expect((await store.read(SessionKind.user))?.token, 'new');
    });

    test('clears only the requested session kind', () async {
      await store.save(const Session.user(token: 'user', subjectId: 'user-1'));
      await store.save(
        const Session.admin(token: 'admin', subjectId: 'admin-1'),
      );

      await store.clear(SessionKind.user);

      expect(await store.read(SessionKind.user), isNull);
      expect(await store.read(SessionKind.admin), isNotNull);
    });

    test('does not reveal the token in string output', () {
      const session = Session.user(token: 'secret-jwt', subjectId: 'user-1');
      expect(session.toString(), isNot(contains('secret-jwt')));
    });
  });
}

void main() {
  sessionStoreContract('SecureSessionStore', SecureSessionStore.fromStorage);
  sessionStoreContract('WebSessionStore', WebSessionStore.fromStorage);
}

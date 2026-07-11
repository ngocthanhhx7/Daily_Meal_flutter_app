import 'package:daily_meal_flutter_app/core/storage/key_value_storage.dart';
import 'package:daily_meal_flutter_app/core/storage/session.dart';

abstract interface class SessionStore {
  Future<Session?> read(SessionKind kind);
  Future<void> save(Session session);
  Future<void> clear(SessionKind kind);
}

class KeyValueSessionStore implements SessionStore {
  KeyValueSessionStore(this._storage, {required this.keyPrefix});

  final KeyValueStorage _storage;
  final String keyPrefix;

  String _key(SessionKind kind) => '$keyPrefix.${kind.name}';

  @override
  Future<void> clear(SessionKind kind) => _storage.delete(_key(kind));

  @override
  Future<Session?> read(SessionKind kind) async {
    final value = await _storage.read(_key(kind));
    return value == null ? null : Session.decode(value);
  }

  @override
  Future<void> save(Session session) =>
      _storage.write(_key(session.kind), session.encode());
}

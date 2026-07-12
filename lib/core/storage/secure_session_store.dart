import 'package:daily_meal_flutter_app/core/storage/key_value_storage.dart';
import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : this.fromStorage(
        _SecureKeyValueStorage(storage ?? const FlutterSecureStorage()),
      );

  SecureSessionStore.fromStorage(KeyValueStorage storage)
    : _delegate = KeyValueSessionStore(
        storage,
        keyPrefix: 'daily_meal.session',
      );

  final KeyValueSessionStore _delegate;

  @override
  Future<void> clear(SessionKind kind) => _delegate.clear(kind);

  @override
  Future<Session?> read(SessionKind kind) => _delegate.read(kind);

  @override
  Future<void> save(Session session) => _delegate.save(session);
}

class _SecureKeyValueStorage implements KeyValueStorage {
  _SecureKeyValueStorage(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

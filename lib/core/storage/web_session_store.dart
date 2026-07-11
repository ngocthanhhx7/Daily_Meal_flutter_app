import 'package:daily_meal_flutter_app/core/storage/key_value_storage.dart';
import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSessionStore implements SessionStore {
  WebSessionStore.fromStorage(KeyValueStorage storage)
    : _delegate = KeyValueSessionStore(
        storage,
        keyPrefix: 'daily_meal.web_session',
      );

  static Future<WebSessionStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return WebSessionStore.fromStorage(_PreferencesStorage(preferences));
  }

  final KeyValueSessionStore _delegate;

  @override
  Future<void> clear(SessionKind kind) => _delegate.clear(kind);

  @override
  Future<Session?> read(SessionKind kind) => _delegate.read(kind);

  @override
  Future<void> save(Session session) => _delegate.save(session);
}

class _PreferencesStorage implements KeyValueStorage {
  _PreferencesStorage(this._preferences);
  final SharedPreferences _preferences;

  @override
  Future<void> delete(String key) async {
    await _preferences.remove(key);
  }

  @override
  Future<String?> read(String key) async => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }
}

import 'package:daily_meal_flutter_app/core/network/auth_token_provider.dart';
import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';

class SessionAuthTokenProvider implements AuthTokenProvider {
  SessionAuthTokenProvider(this._sessions);
  final SessionStore _sessions;

  @override
  Future<String?> readToken() async {
    final admin = await _sessions.read(SessionKind.admin);
    if (admin != null) return admin.token;
    return (await _sessions.read(SessionKind.user))?.token;
  }
}

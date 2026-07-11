import 'package:daily_meal_flutter_app/core/storage/secure_session_store.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:daily_meal_flutter_app/core/storage/web_session_store.dart';
import 'package:flutter/foundation.dart';

Future<SessionStore> createSessionStore() async {
  if (kIsWeb) {
    return WebSessionStore.create();
  }
  return SecureSessionStore();
}

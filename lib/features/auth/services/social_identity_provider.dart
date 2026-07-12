import 'dart:async';

import 'package:daily_meal_flutter_app/features/auth/services/google_sign_in_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract interface class SocialIdentityProvider {
  Stream<String> get googleIdTokens;

  Future<void> initialize({
    required String googleWebClientId,
    required String facebookAppId,
  });

  Widget googleButton({required bool enabled});
  Future<void> authenticateGoogle();
  Future<String?> facebookAccessToken();
  void dispose();
}

class SocialSdkInitializer {
  Future<void>? _initialization;

  Future<void> run(Future<void> Function() initialize) {
    final existing = _initialization;
    if (existing != null) return existing;

    late final Future<void> attempt;
    attempt = Future<void>.sync(initialize).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      if (identical(_initialization, attempt)) _initialization = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    _initialization = attempt;
    return attempt;
  }
}

class PluginSocialIdentityProvider implements SocialIdentityProvider {
  static final SocialSdkInitializer _sdkInitializer = SocialSdkInitializer();

  final _google = GoogleSignIn.instance;
  final _googleTokens = StreamController<String>.broadcast();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;
  bool _initialized = false;

  @override
  Stream<String> get googleIdTokens => _googleTokens.stream;

  @override
  Future<void> initialize({
    required String googleWebClientId,
    required String facebookAppId,
  }) async {
    if (_initialized) return;
    if (googleWebClientId.isEmpty) {
      throw StateError('GOOGLE_WEB_CLIENT_ID chưa được cấu hình.');
    }
    await _sdkInitializer.run(() async {
      await _google.initialize(
        clientId: kIsWeb ? googleWebClientId : null,
        serverClientId: kIsWeb ? null : googleWebClientId,
      );
      if (kIsWeb) {
        if (facebookAppId.isEmpty) {
          throw StateError('FACEBOOK_APP_ID chưa được cấu hình.');
        }
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: facebookAppId,
          cookie: true,
          xfbml: true,
          version: 'v21.0',
        );
      }
    });
    _googleSubscription ??= _google.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final token = event.user.authentication.idToken;
        if (token != null && token.isNotEmpty) _googleTokens.add(token);
      }
    });
    _initialized = true;
  }

  @override
  Widget googleButton({required bool enabled}) {
    return buildGoogleSignInButton(
      onPressed: enabled
          ? () async {
              if (!kIsWeb && _google.supportsAuthenticate()) {
                await _google.authenticate();
              }
            }
          : null,
    );
  }

  @override
  Future<void> authenticateGoogle() async {
    if (!kIsWeb && _google.supportsAuthenticate()) {
      await _google.authenticate();
    }
  }

  @override
  Future<String?> facebookAccessToken() async {
    final result = await FacebookAuth.instance.login();
    return switch (result.status) {
      LoginStatus.success => result.accessToken?.tokenString,
      LoginStatus.cancelled => null,
      _ => throw StateError(result.message ?? 'Facebook login thất bại.'),
    };
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    _googleTokens.close();
  }
}

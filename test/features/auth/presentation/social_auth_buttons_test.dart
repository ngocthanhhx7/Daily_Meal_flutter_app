import 'dart:async';

import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/social_auth_buttons.dart';
import 'package:daily_meal_flutter_app/features/auth/services/social_identity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements AuthRepositoryContract {
  String? googleToken;
  String? facebookToken;

  AppUser get user => AppUser.fromJson({
    'id': 'user-1',
    'displayName': 'Meal',
    'preferences': {'completedOnboarding': true},
  });

  @override
  Future<AppUser> loginWithGoogle(String idToken) async {
    googleToken = idToken;
    return user;
  }

  @override
  Future<AppUser> loginWithFacebook(String accessToken) async {
    facebookToken = accessToken;
    return user;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IdentityProvider implements SocialIdentityProvider {
  final googleTokens = StreamController<String>.broadcast();
  String? initializedGoogleId;
  String? initializedFacebookId;

  @override
  Stream<String> get googleIdTokens => googleTokens.stream;

  @override
  Future<void> initialize({
    required String googleWebClientId,
    required String facebookAppId,
  }) async {
    initializedGoogleId = googleWebClientId;
    initializedFacebookId = facebookAppId;
  }

  @override
  Widget googleButton({required bool enabled}) => OutlinedButton(
    onPressed: enabled ? () => googleTokens.add('google-id-token') : null,
    child: const Text('Tiếp tục với Google'),
  );

  @override
  Future<void> authenticateGoogle() async {
    googleTokens.add('google-id-token');
  }

  @override
  Future<String?> facebookAccessToken() async => 'facebook-access-token';

  @override
  void dispose() => googleTokens.close();
}

void main() {
  testWidgets('initializes SDKs and exchanges Google and Facebook tokens', (
    tester,
  ) async {
    final repository = _Repository();
    final identity = _IdentityProvider();
    final controller = AuthController(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialAuthButtons(
            controller: controller,
            identityProvider: identity,
            googleWebClientId: 'google-client-id',
            facebookAppId: 'facebook-app-id',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(identity.initializedGoogleId, 'google-client-id');
    expect(identity.initializedFacebookId, 'facebook-app-id');

    await tester.tap(find.byKey(const Key('auth-google-button')));
    await tester.pumpAndSettle();
    expect(repository.googleToken, 'google-id-token');

    await tester.tap(find.byKey(const Key('auth-facebook-button')));
    await tester.pumpAndSettle();
    expect(repository.facebookToken, 'facebook-access-token');
  });
}

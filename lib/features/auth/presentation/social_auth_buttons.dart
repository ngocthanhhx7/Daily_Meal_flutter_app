import 'dart:async';

import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/services/social_identity_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SocialAuthButtons extends StatefulWidget {
  const SocialAuthButtons({
    required this.controller,
    required this.googleWebClientId,
    required this.facebookAppId,
    this.onPhonePressed,
    this.identityProvider,
    super.key,
  });

  final AuthController controller;
  final String googleWebClientId;
  final String facebookAppId;
  final VoidCallback? onPhonePressed;
  final SocialIdentityProvider? identityProvider;

  @override
  State<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends State<SocialAuthButtons> {
  late final SocialIdentityProvider _identity;
  late final bool _ownsIdentity;
  StreamSubscription<String>? _googleSubscription;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ownsIdentity = widget.identityProvider == null;
    _identity = widget.identityProvider ?? PluginSocialIdentityProvider();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _googleSubscription = _identity.googleIdTokens.listen(_googleLogin);
      await _identity.initialize(
        googleWebClientId: widget.googleWebClientId,
        facebookAppId: widget.facebookAppId,
      );
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = userErrorMessage(error));
    }
  }

  Future<void> _googleLogin(String token) async {
    await _run(() => widget.controller.loginWithGoogle(token));
  }

  Future<void> _facebookLogin() async {
    final token = await _identity.facebookAccessToken();
    if (token != null) {
      await _run(() => widget.controller.loginWithFacebook(token));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    if (_ownsIdentity) _identity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              key: const Key('auth-facebook-button'),
              tooltip: 'Tiếp tục với Facebook',
              onPressed: _ready && !_busy ? _facebookLogin : null,
              icon: const Icon(Icons.facebook_rounded),
              style: IconButton.styleFrom(
                fixedSize: const Size.square(56),
                backgroundColor: const Color(0xFF8BA58A),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 30),
            if (kIsWeb)
              _RoundSocialButton(
                child: _identity.googleButton(enabled: _ready && !_busy),
              )
            else
              IconButton.filled(
                key: const Key('auth-google-button'),
                tooltip: 'Tiếp tục với Google',
                onPressed: _ready && !_busy
                    ? _identity.authenticateGoogle
                    : null,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(56),
                  backgroundColor: const Color(0xFF8BA58A),
                  foregroundColor: Colors.white,
                ),
              ),
            if (widget.onPhonePressed != null) ...[
              const SizedBox(width: 30),
              Semantics(
                button: true,
                label: 'Số điện thoại',
                child: IconButton.filled(
                  key: const Key('auth-phone-button'),
                  onPressed: _busy ? null : widget.onPhonePressed,
                  icon: const Icon(Icons.phone_outlined),
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(56),
                    backgroundColor: const Color(0xFF8BA58A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_error case final message?) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _RoundSocialButton extends StatelessWidget {
  const _RoundSocialButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: 56,
        child: ColoredBox(
          color: const Color(0xFF8BA58A),
          child: OverflowBox(
            maxWidth: 220,
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 220, height: 56, child: child),
          ),
        ),
      ),
    );
  }
}

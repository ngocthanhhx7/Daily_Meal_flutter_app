import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_validation.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/auth_form_state.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/password_reset_sheet.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/phone_auth_form.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/social_auth_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daily_meal_flutter_app/app/router/app_route.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.controller, super.key});

  static const emailFieldKey = Key('auth-email-field');
  static const passwordFieldKey = Key('auth-password-field');
  static const displayNameFieldKey = Key('auth-display-name-field');

  final AuthController? controller;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  AuthFormMode _mode = AuthFormMode.login;
  bool _usePhone = false;
  String? _emailError;
  String? _passwordError;
  String? _submitError;

  AuthController get _controller =>
      widget.controller ?? ref.read(authControllerProvider);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = AuthValidation.email(_email.text);
    final passwordError = AuthValidation.authPassword(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _submitError = null;
    });
    if (emailError != null || passwordError != null) return;

    try {
      if (_mode == AuthFormMode.login) {
        await _controller.login(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await _controller.register(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _displayName.text.trim().isEmpty
              ? null
              : _displayName.text.trim(),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitError =
              _controller.state.errorMessage ??
              'Không thể xác thực. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller == null
        ? ref.watch(authControllerProvider).state
        : widget.controller!.state;
    final registering = _mode == AuthFormMode.register;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 390,
                minHeight: MediaQuery.sizeOf(context).height,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  image: DecorationImage(
                    image: AssetImage('assets/backgrounds/background1.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 236),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        registering ? 'Tạo tài khoản' : 'Đăng nhập',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        registering
                            ? 'Bắt đầu hành trình ẩm thực của bạn.'
                            : 'Chọn phương thức đăng nhập',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 22),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.email_outlined),
                            label: Text('Email'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.phone_outlined),
                            label: Text('Số điện thoại'),
                          ),
                        ],
                        selected: {_usePhone},
                        onSelectionChanged: (selection) => setState(() {
                          _usePhone = selection.first;
                          _submitError = null;
                        }),
                      ),
                      const SizedBox(height: 20),
                      if (_usePhone)
                        PhoneAuthForm(controller: _controller)
                      else ...[
                        if (registering) ...[
                          TextField(
                            key: LoginScreen.displayNameFieldKey,
                            controller: _displayName,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Tên hiển thị',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          key: LoginScreen.emailFieldKey,
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'Email',
                            errorText: _emailError,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: LoginScreen.passwordFieldKey,
                          controller: _password,
                          obscureText: true,
                          onSubmitted: (_) => _submit(),
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            errorText: _passwordError,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (_submitError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _submitError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: state.isBusy ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: state.isBusy
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  registering ? 'Tạo tài khoản' : 'Đăng nhập',
                                ),
                        ),
                        if (!registering)
                          TextButton(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) =>
                                  PasswordResetSheet(controller: _controller),
                            ),
                            child: const Text('Quên mật khẩu?'),
                          ),
                        if (!registering && widget.controller == null) ...[
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('hoặc'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          SocialAuthButtons(
                            controller: _controller,
                            googleWebClientId: ref
                                .watch(appConfigProvider)
                                .googleWebClientId,
                            facebookAppId: ref
                                .watch(appConfigProvider)
                                .facebookAppId,
                          ),
                          const SizedBox(height: 12),
                        ],
                        const Divider(),
                        TextButton(
                          onPressed: () => setState(() {
                            _mode = registering
                                ? AuthFormMode.login
                                : AuthFormMode.register;
                            _emailError = null;
                            _passwordError = null;
                          }),
                          child: Text(
                            registering
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Tạo tài khoản',
                          ),
                        ),
                        if (!registering)
                          TextButton.icon(
                            onPressed: () =>
                                context.goNamed(AppRoute.adminLogin.name),
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: const Text('Đăng nhập quản trị'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

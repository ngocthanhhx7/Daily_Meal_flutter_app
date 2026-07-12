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
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 236),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        registering ? 'Tạo tài khoản' : 'Đăng nhập',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.black,
                              fontSize: 30,
                              height: 37 / 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
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
                      const SizedBox(height: 16),
                      if (_usePhone) ...[
                        PhoneAuthForm(controller: _controller),
                        TextButton(
                          onPressed: () => setState(() => _usePhone = false),
                          child: const Text('Đăng nhập bằng email'),
                        ),
                      ] else ...[
                        if (!registering)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Đăng nhập vào tài khoản hiện có',
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        if (registering) ...[
                          _FigmaAuthField(
                            label: 'Tên hiển thị',
                            child: TextField(
                              key: LoginScreen.displayNameFieldKey,
                              controller: _displayName,
                              textInputAction: TextInputAction.next,
                              decoration: _figmaInputDecoration(
                                hintText: 'Nguyễn Văn A',
                              ),
                            ),
                          ),
                        ],
                        _FigmaAuthField(
                          label: registering ? 'Email' : 'Tên đăng nhập',
                          child: TextField(
                            key: LoginScreen.emailFieldKey,
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: _figmaInputDecoration(
                              hintText: registering
                                  ? 'email@example.com'
                                  : 'Nhập tên đăng nhập',
                              errorText: _emailError,
                            ),
                          ),
                        ),
                        _FigmaAuthField(
                          label: 'Mật khẩu',
                          child: TextField(
                            key: LoginScreen.passwordFieldKey,
                            controller: _password,
                            obscureText: true,
                            onSubmitted: (_) => _submit(),
                            autofillHints: const [AutofillHints.password],
                            decoration: _figmaInputDecoration(
                              hintText: 'Nhập mật khẩu',
                              errorText: _passwordError,
                            ),
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
                        const SizedBox(height: 2),
                        FilledButton(
                          onPressed: state.isBusy ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: AppColors.black,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
                        TextButton(
                          key: const Key('auth-mode-button'),
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
                                : 'Chưa có tài khoản? Đăng ký ngay',
                          ),
                        ),
                        if (!registering) ...[
                          TextButton(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) =>
                                  PasswordResetSheet(controller: _controller),
                            ),
                            child: const Text('Quên mật khẩu?'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.goNamed(AppRoute.adminLogin.name),
                            child: const Text('Đăng nhập admin'),
                          ),
                        ],
                        if (!registering && widget.controller == null) ...[
                          const SizedBox(height: 24),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Phương thức đăng nhập khác',
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SocialAuthButtons(
                            controller: _controller,
                            googleWebClientId: ref
                                .watch(appConfigProvider)
                                .googleWebClientId,
                            facebookAppId: ref
                                .watch(appConfigProvider)
                                .facebookAppId,
                            onPhonePressed: () =>
                                setState(() => _usePhone = true),
                          ),
                        ] else if (!registering) ...[
                          Center(
                            child: IconButton.filled(
                              key: const Key('auth-phone-button'),
                              onPressed: () => setState(() => _usePhone = true),
                              icon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                        ],
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

class _FigmaAuthField extends StatelessWidget {
  const _FigmaAuthField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color.fromRGBO(68, 68, 68, 0.62),
              fontSize: 12,
              height: 15 / 12,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.16),
                  offset: Offset(0, 4),
                  blurRadius: 15,
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

InputDecoration _figmaInputDecoration({
  required String hintText,
  String? errorText,
}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(14),
      topRight: Radius.circular(14),
      bottomLeft: Radius.circular(12),
    ),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    filled: true,
    fillColor: AppColors.white,
    isDense: true,
    constraints: const BoxConstraints(minHeight: 44),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.red),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.red),
    ),
  );
}

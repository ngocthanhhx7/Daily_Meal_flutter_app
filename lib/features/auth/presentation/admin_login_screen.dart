import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({this.controller, super.key});

  static const emailFieldKey = Key('admin-email-field');
  static const passwordFieldKey = Key('admin-password-field');

  final AuthController? controller;

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _submitError;

  AuthController get _controller =>
      widget.controller ?? ref.read(authControllerProvider);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
      await _controller.adminLogin(
        email: _email.text.trim(),
        password: _password.text,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitError =
              _controller.state.errorMessage ?? 'Đăng nhập admin thất bại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller == null
        ? ref.watch(authControllerProvider).state
        : widget.controller!.state;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 60,
                        color: AppColors.greenDark,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Daily Meal Admin',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Đăng nhập bằng tài khoản quản trị đã cấu hình trên server.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        key: AdminLoginScreen.emailFieldKey,
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email admin',
                          errorText: _emailError,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: AdminLoginScreen.passwordFieldKey,
                        controller: _password,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          errorText: _passwordError,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (_submitError case final message?) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: state.isBusy ? null : _submit,
                        child: state.isBusy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Đăng nhập admin'),
                      ),
                      TextButton(
                        onPressed: () => context.goNamed(AppRoute.login.name),
                        child: const Text('Quay lại trang chính'),
                      ),
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

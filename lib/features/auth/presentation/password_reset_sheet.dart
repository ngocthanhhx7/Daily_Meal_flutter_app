import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_validation.dart';
import 'package:flutter/material.dart';

class PasswordResetSheet extends StatefulWidget {
  const PasswordResetSheet({required this.controller, super.key});

  static const emailFieldKey = Key('reset-email-field');
  static const otpFieldKey = Key('reset-otp-field');
  static const newPasswordFieldKey = Key('reset-new-password-field');

  final AuthController controller;

  @override
  State<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<PasswordResetSheet> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error =
        AuthValidation.email(_email.text) ??
        (_otpSent ? AuthValidation.otp(_otp.text) : null) ??
        (_otpSent ? AuthValidation.resetPassword(_newPassword.text) : null);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_otpSent) {
        await widget.controller.requestPasswordResetOtp(_email.text.trim());
        if (mounted) {
          setState(() => _otpSent = true);
        }
      } else {
        await widget.controller.verifyPasswordResetOtp(
          email: _email.text.trim(),
          otp: _otp.text.trim(),
          newPassword: _newPassword.text,
        );
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể xử lý yêu cầu. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quên mật khẩu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                key: PasswordResetSheet.emailFieldKey,
                controller: _email,
                enabled: !_otpSent,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 12),
                TextField(
                  key: PasswordResetSheet.otpFieldKey,
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mã OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: PasswordResetSheet.newPasswordFieldKey,
                  controller: _newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(_otpSent ? 'Xác nhận OTP' : 'Gửi OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

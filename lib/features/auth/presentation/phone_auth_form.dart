import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_validation.dart';
import 'package:flutter/material.dart';

class PhoneAuthForm extends StatefulWidget {
  const PhoneAuthForm({required this.controller, super.key});

  static const phoneFieldKey = Key('phone-auth-phone');
  static const otpFieldKey = Key('phone-auth-otp');
  static const passwordFieldKey = Key('phone-auth-password');
  static const displayNameFieldKey = Key('phone-auth-display-name');

  final AuthController controller;

  @override
  State<PhoneAuthForm> createState() => _PhoneAuthFormState();
}

class _PhoneAuthFormState extends State<PhoneAuthForm> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _otpSent = false;
  bool _requiresPasswordSetup = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validation =
        AuthValidation.phone(_phone.text) ??
        (_otpSent ? AuthValidation.otp(_otp.text) : null) ??
        (_otpSent && _requiresPasswordSetup
            ? AuthValidation.authPassword(_password.text)
            : null);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_otpSent) {
        final response = await widget.controller.requestPhoneOtp(
          _phone.text.trim(),
        );
        if (mounted) {
          setState(() {
            _otpSent = true;
            _requiresPasswordSetup = response.requiresPasswordSetup;
          });
        }
      } else {
        await widget.controller.verifyPhoneOtp(
          phone: _phone.text.trim(),
          otp: _otp.text.trim(),
          password: _requiresPasswordSetup ? _password.text : null,
          displayName:
              _requiresPasswordSetup && _displayName.text.trim().isNotEmpty
              ? _displayName.text.trim()
              : null,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không thể xác thực số điện thoại. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: PhoneAuthForm.phoneFieldKey,
          controller: _phone,
          enabled: !_otpSent,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            border: OutlineInputBorder(),
          ),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 12),
          TextField(
            key: PhoneAuthForm.otpFieldKey,
            controller: _otp,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mã OTP',
              border: OutlineInputBorder(),
            ),
          ),
          if (_requiresPasswordSetup) ...[
            const SizedBox(height: 12),
            TextField(
              key: PhoneAuthForm.displayNameFieldKey,
              controller: _displayName,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: PhoneAuthForm.passwordFieldKey,
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Tạo mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(_otpSent ? 'Xác nhận OTP' : 'Gửi OTP'),
        ),
      ],
    );
  }
}

abstract final class AuthValidation {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _otpPattern = RegExp(r'^\d{6}$');

  static String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Vui lòng nhập email.';
    if (!_emailPattern.hasMatch(normalized)) {
      return 'Vui lòng nhập đúng định dạng email.';
    }
    return null;
  }

  static String? phone(String value) =>
      value.trim().isEmpty ? 'Vui lòng nhập số điện thoại.' : null;

  static String? otp(String value) => _otpPattern.hasMatch(value.trim())
      ? null
      : 'Vui lòng nhập mã OTP gồm 6 chữ số.';

  static String? authPassword(String value) =>
      value.trim().length >= 6 ? null : 'Mật khẩu cần ít nhất 6 ký tự.';

  static String? resetPassword(String value) =>
      value.trim().length >= 8 ? null : 'Mật khẩu mới cần ít nhất 8 ký tự.';
}

import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'] as String,
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String token;
  final AppUser user;
}

class PhoneOtpResponse {
  const PhoneOtpResponse({required this.requiresPasswordSetup, this.devOtp});

  factory PhoneOtpResponse.fromJson(Map<String, dynamic> json) =>
      PhoneOtpResponse(
        requiresPasswordSetup: json['requiresPasswordSetup'] as bool? ?? false,
        devOtp: json['devOtp'] as String?,
      );

  final bool requiresPasswordSetup;
  final String? devOtp;
}

class OtpRequestResponse {
  const OtpRequestResponse({required this.message, this.devOtp});

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) =>
      OtpRequestResponse(
        message: json['message'] as String? ?? '',
        devOtp: json['devOtp'] as String?,
      );

  final String message;
  final String? devOtp;
}

class AdminAuthResult {
  const AdminAuthResult({
    required this.token,
    required this.email,
    required this.displayName,
  });

  factory AdminAuthResult.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>;
    return AdminAuthResult(
      token: json['token'] as String,
      email: admin['email'] as String,
      displayName: admin['displayName'] as String,
    );
  }

  final String token;
  final String email;
  final String displayName;
}

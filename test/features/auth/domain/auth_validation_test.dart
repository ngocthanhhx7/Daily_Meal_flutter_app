import 'package:daily_meal_flutter_app/features/auth/domain/auth_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email authentication', () {
    test('requires a valid email and six-character password', () {
      expect(AuthValidation.email('bad'), isNotNull);
      expect(AuthValidation.email('meal@example.com'), isNull);
      expect(AuthValidation.authPassword('12345'), isNotNull);
      expect(AuthValidation.authPassword('123456'), isNull);
    });
  });

  group('phone OTP', () {
    test('requires a phone and exactly six numeric OTP characters', () {
      expect(AuthValidation.phone('  '), isNotNull);
      expect(AuthValidation.phone('+84901234567'), isNull);
      expect(AuthValidation.otp('12345'), isNotNull);
      expect(AuthValidation.otp('12345a'), isNotNull);
      expect(AuthValidation.otp('123456'), isNull);
    });
  });

  test('requires eight characters for a reset password', () {
    expect(AuthValidation.resetPassword('1234567'), isNotNull);
    expect(AuthValidation.resetPassword('12345678'), isNull);
  });
}

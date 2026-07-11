import 'package:daily_meal_flutter_app/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses safe Vietnamese messages for each failure kind', () {
    expect(
      const AppFailure.unauthorized().userMessage,
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    );
    expect(
      const AppFailure.network().userMessage,
      'Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.',
    );
    expect(
      const AppFailure.validation(message: 'Tên không hợp lệ').userMessage,
      'Tên không hợp lệ',
    );
  });

  test('does not expose technical details through the user message', () {
    const failure = AppFailure.server(
      technicalMessage: 'Authorization: Bearer secret-token',
    );

    expect(failure.userMessage, isNot(contains('secret-token')));
    expect(failure.technicalMessage, contains('secret-token'));
  });
}
